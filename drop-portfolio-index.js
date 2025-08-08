const mongoose = require('mongoose');
require('dotenv').config();

async function dropPortfolioIndex() {
  try {
    // Connect to MongoDB
    await mongoose.connect(process.env.MONGODB_URI);
    console.log('✅ Connected to MongoDB');

    // Get the Portfolio collection
    const db = mongoose.connection.db;
    const collection = db.collection('portfolios');

    // List existing indexes
    console.log('\n📋 Current indexes on portfolios collection:');
    const indexes = await collection.indexes();
    indexes.forEach((index, i) => {
      console.log(`${i + 1}. ${index.name}:`, JSON.stringify(index.key));
    });

    // Drop the global unique index on profilename
    try {
      await collection.dropIndex('profilename_1');
      console.log('\n✅ Successfully dropped profilename_1 unique index');
    } catch (error) {
      if (error.code === 27) {
        console.log('\n⚠️  Index profilename_1 does not exist (already dropped)');
      } else {
        console.log('\n❌ Error dropping index:', error.message);
      }
    }

    // List indexes after dropping
    console.log('\n📋 Indexes after dropping:');
    const indexesAfter = await collection.indexes();
    indexesAfter.forEach((index, i) => {
      console.log(`${i + 1}. ${index.name}:`, JSON.stringify(index.key));
    });

    console.log('\n🎉 Index management completed!');
    console.log('Now multiple users can have portfolios with the same default category names.');

  } catch (error) {
    console.error('❌ Error:', error);
  } finally {
    await mongoose.disconnect();
    console.log('✅ Disconnected from MongoDB');
  }
}

// Run the script
dropPortfolioIndex();
