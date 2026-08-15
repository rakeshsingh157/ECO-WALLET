const mongoose = require("mongoose");
const dotenv = require("dotenv");
const Customer = require("./models/Customer");
const Supplier = require("./models/Supplier");
const Expense = require("./models/Expense");
const NotificationItem = require("./models/NotificationItem");

dotenv.config();

const seedData = async () => {
  try {
    const mongoURI = process.env.MONGO_URI || "mongodb://127.0.0.1:27017/billing_soft";
    await mongoose.connect(mongoURI);

    const customerCount = await Customer.countDocuments();
    if (customerCount === 0) {
      await Customer.create([
        {
          customer_id: "cust_1",
          name: "Ramesh Sharma",
          phone: "9876543210",
          address: "Shop 12, Main Market",
          due_amount: 1450,
          total_spent: 8500,
          total_orders: 14,
          last_transaction: new Date(),
        },
        {
          customer_id: "cust_2",
          name: "Pooja Verma",
          phone: "9812345678",
          address: "Flat 4B, Green Avenue",
          due_amount: 0,
          total_spent: 4200,
          total_orders: 8,
          last_transaction: new Date(),
        },
        {
          customer_id: "cust_3",
          name: "Amit Patel",
          phone: "9700012345",
          address: "Sector 14, Ring Road",
          due_amount: 620,
          total_spent: 3100,
          total_orders: 5,
          last_transaction: new Date(),
        },
      ]);
    }

    const supplierCount = await Supplier.countDocuments();
    if (supplierCount === 0) {
      await Supplier.create([
        {
          supplier_id: "sup_1",
          name: "Vijay Trading Co.",
          company_name: "Vijay FMCG Wholesalers",
          phone: "9822334455",
          gstin: "07AAAAA0000A1Z5",
          address: "Grain Market Yard, Gate 2",
          pending_payment: 12400,
          total_supplied: 94000,
          orders_supplied: 18,
          last_order_date: new Date(),
        },
        {
          supplier_id: "sup_2",
          name: "Balaji Dairy Supplies",
          company_name: "Balaji Dairy & Beverages",
          phone: "9833445566",
          gstin: "07BBBBB1111B1Z2",
          address: "Industrial Area Phase 1",
          pending_payment: 0,
          total_supplied: 45000,
          orders_supplied: 32,
          last_order_date: new Date(),
        },
      ]);
    }

    const expenseCount = await Expense.countDocuments();
    if (expenseCount === 0) {
      await Expense.create([
        {
          expense_id: "exp_1",
          title: "Shop Electricity Bill",
          amount: 1450,
          category: "Utilities",
          payment_mode: "UPI",
          notes: "Monthly power bill",
          date: new Date(),
        },
        {
          expense_id: "exp_2",
          title: "Packaging Bags & Cartons",
          amount: 500,
          category: "Other",
          payment_mode: "Cash",
          notes: "500 carry bags",
          date: new Date(),
        },
      ]);
    }

    const notifCount = await NotificationItem.countDocuments();
    if (notifCount === 0) {
      await NotificationItem.create([
        {
          notification_id: "notif_1",
          title: "Low Stock Alert: Mustard Oil",
          message: "Fortune Mustard Oil has only 3 units remaining in stock.",
          type: "warning",
          is_read: false,
        },
        {
          notification_id: "notif_2",
          title: "Khata Payment Received",
          message: "Ramesh Sharma cleared ₹500 via Cash settlement.",
          type: "success",
          is_read: false,
        },
      ]);
    }

    console.log("[INFO] Database seeded successfully");
    process.exit(0);
  } catch (err) {
    console.error("[ERROR] Seeder error:", err.message);
    process.exit(1);
  }
};

seedData();
