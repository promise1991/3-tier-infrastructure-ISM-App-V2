require('dotenv').config();
const mongoose = require('mongoose');

const connectToMongo = async () => {
  try {
    mongoose.set("strictQuery", false);
    console.log("==== CURRENT MONGO_URI:", process.env.MONGO_URI);
    await mongoose.connect(process.env.MONGO_URI);
    console.log("MONGO_URI from env:", process.env.MONGO_URI)
    console.log("Connected to Mongo Successfully!");
  } catch (error) {
    console.error("MongoDB Connection Error:", error);
  }
};

module.exports = connectToMongo;