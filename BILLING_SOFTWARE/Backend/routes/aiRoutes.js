const express = require("express");
const router = express.Router();
const Product = require("../models/Product");

const NUMBER_WORDS = {
  "ek": 1, "doh": 2, "do": 2, "teen": 3, "char": 4, "chaar": 4, "paanch": 5, "panch": 5, "chhe": 6, "che": 6, "saat": 7, "aath": 8, "nau": 9, "das": 10,
  "one": 1, "two": 2, "three": 3, "four": 4, "five": 5, "six": 6, "seven": 7, "eight": 8, "nine": 9, "ten": 10,
  "ondru": 1, "irandu": 2, "moondru": 3, "naangu": 4, "ainthu": 5,
  "okati": 1, "rendu": 2, "moodu": 3, "naalugu": 4, "aidu": 5,
  "ek1": 1, "don": 2, "tin": 3, "char1": 4, "paach": 5
};

const MULTI_LANG_SYNONYMS = {
  "sugar": ["chini", "cheeni", "shakkar", "sakhar", "khand", "sarkarai", "chakkara", "cheeni", "ખાંડ", "साखर", "चीनी", "சர்க்கரை", "చక్కెర"],
  "milk": ["doodh", "dudh", "dhoodh", "paal", "paalu", "dood", "દૂધ", "दूध", "பால்", "పాలు"],
  "water": ["pani", "paani", "neer", "neellu", "thanner", "jal", "પાણી", "पाणी", "पानी", "தண்ணீர்", "నీళ్లు"],
  "oil": ["tel", "tail", "telam", "yennai", "nunne", "telu", "તેલ", "तेल", "எண்ணெய்", "నూనె"],
  "rice": ["chawal", "tandul", "chokha", "arisi", "biyyam", "tandool", "ચોખા", "तांदूळ", "चावल", "அரிசி", "బియ్యం"],
  "flour": ["atta", "aata", "pith", "maida", "ravai", "godhumai", "pindi", "લોટ", "पीठ", "आटा", "மாவு", "పిండి"],
  "salt": ["namak", "meeth", "mithu", "uppu", "lavan", "મીઠું", "मीठ", "नमक", "உப்பு", "ఉప్పు"],
  "tea": ["chai", "chaha", "cha", "theeneer", "tea", "ચા", "चहा", "चाय", "தேநீர்", "టీ"],
  "soap": ["sabun", "saabu", "soap", "sabbu", "સાબુ", "साबण", "साबुन", "சோப்பு", "సబ్బు"],
  "biscuit": ["biscuit", "biscuits", "parle", "cookies", "બિસ્કિટ", "बिस्कीट", "बिस्कुट", "பிஸ்கட்", "బిస్కెట్"],
  "dal": ["dal", "daal", "paruppu", "pappu", "pulse", "lentils", "દાળ", "डाळ", "दाल", "பருப்பு", "పప్పు"]
};

function mapLanguageToSarvam(langCode) {
  switch ((langCode || "").toLowerCase().trim()) {
    case "hi":
      return "hi-IN";
    case "mr":
      return "mr-IN";
    case "gu":
      return "gu-IN";
    case "ta":
      return "ta-IN";
    case "te":
      return "te-IN";
    case "en":
      return "en-IN";
    default:
      return "unknown";
  }
}

async function transcribeWithSarvam(base64Audio, languageCode, format) {
  const sarvamKey = process.env.SARVAM_API_KEY;
  if (!sarvamKey || sarvamKey.trim().length < 5) {
    return null;
  }

  try {
    const audioBuffer = Buffer.from(base64Audio, "base64");
    const mimeType = format === "wav" ? "audio/wav" : (format === "m4a" ? "audio/m4a" : "audio/aac");
    const fileName = `speech.${format || "m4a"}`;

    const blob = new Blob([audioBuffer], { type: mimeType });
    const formData = new FormData();
    formData.append("file", blob, fileName);
    formData.append("model", "saaras:v1");
    if (languageCode && languageCode !== "unknown") {
      formData.append("language_code", languageCode);
    }

    const response = await fetch("https://api.sarvam.ai/speech-to-text", {
      method: "POST",
      headers: {
        "api-subscription-key": sarvamKey.trim()
      },
      body: formData
    });

    if (response.ok) {
      const data = await response.json();
      if (data && data.transcript && data.transcript.trim().length > 0) {
        return data.transcript.trim();
      }
    }
  } catch (_) {
  }
  return null;
}

function fallbackFuzzyMatch(spokenText, products) {
  const words = spokenText.toLowerCase().replace(/[,.-]/g, " ").split(/\s+/).filter(Boolean);
  const matched = [];
  const unmatched = [];
  const processedIndices = new Set();

  for (let i = 0; i < words.length; i++) {
    if (processedIndices.has(i)) continue;

    let qty = 1;
    let unit = "pcs";
    let token = words[i];

    if (/^\d+(\.\d+)?$/.test(token)) {
      qty = parseFloat(token);
      processedIndices.add(i);
      if (i + 1 < words.length && ["kg", "g", "gm", "gram", "grams", "kilo", "l", "ltr", "liter", "litre", "bottle", "bottles", "packet", "packets", "pkt", "pkts", "pc", "pcs", "piece", "pieces", "can", "cans"].includes(words[i + 1])) {
        unit = words[i + 1];
        processedIndices.add(i + 1);
        i++;
      }
      if (i + 1 < words.length) {
        token = words[i + 1];
        processedIndices.add(i + 1);
        i++;
      }
    } else if (NUMBER_WORDS[token]) {
      qty = NUMBER_WORDS[token];
      processedIndices.add(i);
      if (i + 1 < words.length && ["kg", "g", "gm", "gram", "grams", "kilo", "l", "ltr", "liter", "litre", "bottle", "bottles", "packet", "packets", "pkt", "pkts", "pc", "pcs", "piece", "pieces"].includes(words[i + 1])) {
        unit = words[i + 1];
        processedIndices.add(i + 1);
        i++;
      }
      if (i + 1 < words.length) {
        token = words[i + 1];
        processedIndices.add(i + 1);
        i++;
      }
    }

    if (!token || ["kg", "gm", "bottle", "packet", "and", "aur", "aur1", "mathe", "evam", "to", "ke", "ka", "ki"].includes(token)) {
      continue;
    }

    let foundProduct = products.find(p => p.name.toLowerCase().includes(token));

    if (!foundProduct) {
      for (const [canonical, syns] of Object.entries(MULTI_LANG_SYNONYMS)) {
        if (syns.includes(token) || canonical === token) {
          foundProduct = products.find(p => {
            const pName = p.name.toLowerCase();
            return pName.includes(canonical) || syns.some(s => pName.includes(s));
          });
          if (foundProduct) break;
        }
      }
    }

    if (foundProduct) {
      const alreadyInMatched = matched.find(m => m.id === (foundProduct.product_id || foundProduct._id.toString()));
      if (alreadyInMatched) {
        alreadyInMatched.quantity += qty;
      } else {
        matched.push({
          id: foundProduct.product_id || foundProduct._id.toString(),
          product_id: foundProduct.product_id || foundProduct._id.toString(),
          name: foundProduct.name,
          price: foundProduct.price,
          unit: foundProduct.unit || unit,
          stock: foundProduct.stock,
          category: foundProduct.category,
          quantity: qty
        });
      }
    } else {
      unmatched.push({
        name: token,
        quantity: qty,
        unit: unit,
        reason: "not_found"
      });
    }
  }

  return { matched, unmatched };
}

router.post("/voice-to-cart", async (req, res) => {
  try {
    const { audio, text, language, format } = req.body;
    let spokenText = "";
    let sarvamUsed = false;

    if (audio && typeof audio === "string" && audio.trim().length > 20) {
      const sarvamLang = mapLanguageToSarvam(language);
      const transcribed = await transcribeWithSarvam(audio.trim(), sarvamLang, format || "m4a");
      if (transcribed && transcribed.length > 0) {
        spokenText = transcribed;
        sarvamUsed = true;
      }
    }

    if (!spokenText && text && typeof text === "string" && text.trim().length > 0) {
      spokenText = text.trim();
    }

    if (!spokenText || spokenText.length === 0) {
      return res.status(400).json({
        success: false,
        message: "Spoken audio recording or transcript text is required",
        matched: [],
        unmatched: []
      });
    }

    const products = await Product.find({}).lean();

    if (!products || products.length === 0) {
      return res.json({
        success: true,
        rawText: spokenText,
        sarvamUsed,
        provider: "none",
        matched: [],
        unmatched: [{ name: spokenText, quantity: 1, unit: "pcs", reason: "inventory_empty" }]
      });
    }

    const mistralApiKey = process.env.MISTRAL_API_KEY;

    if (mistralApiKey && mistralApiKey.trim().length > 5) {
      try {
        const inventorySummary = products.map(p => ({
          id: p.product_id || p._id.toString(),
          name: p.name,
          category: p.category,
          unit: p.unit,
          price: p.price,
          stock: p.stock
        }));

        const systemPrompt = `You are an expert AI retail cashier assistant for Dukaan Dost billing software in India.
The user speaks their order items in Indian languages (Hindi, Hinglish, Marathi, Tamil, Telugu, Gujarati, or English), for example: "1 kg chini 1 bottle pani" or "2 packet doodh 500g chai".
Your task is to parse all items, their requested quantities and units, and match them against the merchant's available inventory.

Available Merchant Inventory:
${JSON.stringify(inventorySummary)}

Strict Response Format (ONLY return valid JSON):
{
  "matched": [
    {
      "id": "exact product id from inventory",
      "quantity": number,
      "unit": "requested or product unit"
    }
  ],
  "unmatched": [
    {
      "name": "requested product name as spoken",
      "quantity": number,
      "unit": "requested unit",
      "reason": "not_in_inventory"
    }
  ]
}`;

        const mistralResponse = await fetch("https://api.mistral.ai/v1/chat/completions", {
          method: "POST",
          headers: {
            "Authorization": `Bearer ${mistralApiKey}`,
            "Content-Type": "application/json"
          },
          body: JSON.stringify({
            model: "mistral-small-latest",
            messages: [
              { role: "system", content: systemPrompt },
              { role: "user", content: `Spoken order: "${spokenText}" (Language: ${language || "auto"})` }
            ],
            response_format: { type: "json_object" },
            temperature: 0.1
          })
        });

        if (mistralResponse.ok) {
          const aiData = await mistralResponse.json();
          const parsedContent = JSON.parse(aiData.choices[0].message.content);

          const matchedList = [];
          if (Array.isArray(parsedContent.matched)) {
            for (const item of parsedContent.matched) {
              const matchedProduct = products.find(p => (p.product_id || p._id.toString()) === item.id);
              if (matchedProduct) {
                matchedList.push({
                  id: matchedProduct.product_id || matchedProduct._id.toString(),
                  product_id: matchedProduct.product_id || matchedProduct._id.toString(),
                  name: matchedProduct.name,
                  price: matchedProduct.price,
                  unit: matchedProduct.unit || item.unit || "pcs",
                  stock: matchedProduct.stock,
                  category: matchedProduct.category,
                  quantity: typeof item.quantity === "number" && item.quantity > 0 ? item.quantity : 1
                });
              }
            }
          }

          return res.json({
            success: true,
            sarvamUsed,
            provider: "mistral",
            rawText: spokenText,
            matched: matchedList,
            unmatched: Array.isArray(parsedContent.unmatched) ? parsedContent.unmatched : []
          });
        }
      } catch (_) {
      }
    }

    const { matched, unmatched } = fallbackFuzzyMatch(spokenText, products);

    return res.json({
      success: true,
      sarvamUsed,
      provider: "fallback_fuzzy",
      rawText: spokenText,
      matched,
      unmatched
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      error: error.message,
      matched: [],
      unmatched: []
    });
  }
});

module.exports = router;
