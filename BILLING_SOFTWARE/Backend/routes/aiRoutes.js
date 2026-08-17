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
    return { transcript: null, error: "SARVAM_API_KEY is not configured in backend environment variables" };
  }

  const modelsToTry = [
    process.env.SARVAM_MODEL || "saaras:v4",
    "saaras:v3",
    "saaras:v2"
  ];

  const audioBuffer = Buffer.from(base64Audio, "base64");
  const mimeType = format === "wav" ? "audio/wav" : (format === "m4a" ? "audio/m4a" : "audio/aac");
  const fileName = `speech.${format || "m4a"}`;

  let lastError = null;

  for (const modelName of modelsToTry) {
    try {
      const blob = new Blob([audioBuffer], { type: mimeType });
      const formData = new FormData();
      formData.append("file", blob, fileName);
      formData.append("model", modelName);
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
          return { transcript: data.transcript.trim(), error: null, model: modelName };
        }
      } else {
        const errText = await response.text();
        lastError = `Sarvam API error (${response.status}): ${errText}`;
      }
    } catch (e) {
      lastError = e.message;
    }
  }

  return { transcript: null, error: lastError };
}

function extractJSONFromText(rawText) {
  if (!rawText || typeof rawText !== "string") return null;

  try {
    return JSON.parse(rawText.trim());
  } catch (_) {}

  try {
    const cleaned = rawText.replace(/```(?:json)?/gi, "").replace(/```/g, "").trim();
    return JSON.parse(cleaned);
  } catch (_) {}

  try {
    const firstBrace = rawText.indexOf("{");
    const lastBrace = rawText.lastIndexOf("}");
    if (firstBrace !== -1 && lastBrace !== -1 && lastBrace > firstBrace) {
      const jsonCandidate = rawText.substring(firstBrace, lastBrace + 1);
      return JSON.parse(jsonCandidate);
    }
  } catch (_) {}

  return null;
}

function findProductInInventory(queryIdentifier, queryName, products) {
  const queryIdLower = (queryIdentifier || "").toString().toLowerCase().trim();
  const queryNameLower = (queryName || "").toString().toLowerCase().trim();

  let found = products.find(p => {
    const pId = (p.product_id || p._id.toString()).toLowerCase();
    return pId === queryIdLower;
  });
  if (found) return found;

  if (queryNameLower) {
    found = products.find(p => p.name.toLowerCase() === queryNameLower);
    if (found) return found;
  }

  if (queryIdLower) {
    found = products.find(p => p.name.toLowerCase() === queryIdLower);
    if (found) return found;
  }

  const token = queryNameLower || queryIdLower;
  if (token) {
    found = products.find(p => p.name.toLowerCase().includes(token) || token.includes(p.name.toLowerCase()));
    if (found) return found;

    for (const [canonical, syns] of Object.entries(MULTI_LANG_SYNONYMS)) {
      if (syns.includes(token) || canonical === token) {
        found = products.find(p => {
          const pName = p.name.toLowerCase();
          return pName.includes(canonical) || syns.some(s => pName.includes(s));
        });
        if (found) return found;
      }
    }
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

    const foundProduct = findProductInInventory(token, token, products);

    if (foundProduct) {
      const pId = foundProduct.product_id || foundProduct._id.toString();
      const alreadyInMatched = matched.find(m => m.id === pId);
      if (alreadyInMatched) {
        alreadyInMatched.quantity += qty;
      } else {
        matched.push({
          id: pId,
          product_id: pId,
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
    let sarvamError = null;

    if (audio && typeof audio === "string" && audio.trim().length > 20) {
      const sarvamLang = mapLanguageToSarvam(language);
      const sarvamRes = await transcribeWithSarvam(audio.trim(), sarvamLang, format || "m4a");
      if (sarvamRes.transcript && sarvamRes.transcript.length > 0) {
        spokenText = sarvamRes.transcript;
        sarvamUsed = true;
      } else {
        sarvamError = sarvamRes.error;
      }
    }

    if (!spokenText && text && typeof text === "string" && text.trim().length > 0) {
      spokenText = text.trim();
    }

    if (!spokenText || spokenText.length === 0) {
      const errMsg = sarvamError || "Spoken audio recording or transcript text is required. Please check SARVAM_API_KEY in Render environment.";
      return res.json({
        success: false,
        message: errMsg,
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

Strict Response Format (ONLY return valid JSON without commentary):
{
  "matched": [
    {
      "id": "exact product id from inventory",
      "name": "exact product name from inventory",
      "quantity": 1,
      "unit": "kg"
    }
  ],
  "unmatched": [
    {
      "name": "requested item name as spoken",
      "quantity": 1,
      "unit": "pcs",
      "reason": "not_in_inventory"
    }
  ]
}`;

        const mistralModel = process.env.MISTRAL_MODEL || "mistral-large-latest";

        const mistralResponse = await fetch("https://api.mistral.ai/v1/chat/completions", {
          method: "POST",
          headers: {
            "Authorization": `Bearer ${mistralApiKey}`,
            "Content-Type": "application/json"
          },
          body: JSON.stringify({
            model: mistralModel,
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
          const rawMessageContent = aiData.choices && aiData.choices[0] && aiData.choices[0].message ? aiData.choices[0].message.content : "";
          const parsedContent = extractJSONFromText(rawMessageContent);

          if (parsedContent) {
            const matchedList = [];
            const unmatchedList = Array.isArray(parsedContent.unmatched) ? parsedContent.unmatched : [];

            if (Array.isArray(parsedContent.matched)) {
              for (const item of parsedContent.matched) {
                const matchedProduct = findProductInInventory(item.id, item.name, products);
                const rawQty = typeof item.quantity === "number" ? item.quantity : parseFloat(item.quantity);
                const safeQty = !isNaN(rawQty) && rawQty > 0 ? rawQty : 1;

                if (matchedProduct) {
                  const pId = matchedProduct.product_id || matchedProduct._id.toString();
                  const existing = matchedList.find(m => m.id === pId);
                  if (existing) {
                    existing.quantity += safeQty;
                  } else {
                    matchedList.push({
                      id: pId,
                      product_id: pId,
                      name: matchedProduct.name,
                      price: matchedProduct.price,
                      unit: matchedProduct.unit || item.unit || "pcs",
                      stock: matchedProduct.stock,
                      category: matchedProduct.category,
                      quantity: safeQty
                    });
                  }
                } else {
                  unmatchedList.push({
                    name: item.name || item.id || "Unknown item",
                    quantity: safeQty,
                    unit: item.unit || "pcs",
                    reason: "not_found"
                  });
                }
              }
            }

            return res.json({
              success: true,
              sarvamUsed,
              provider: `mistral (${mistralModel})`,
              rawText: spokenText,
              matched: matchedList,
              unmatched: unmatchedList
            });
          }
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
