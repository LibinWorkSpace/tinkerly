const cloudinary = require('cloudinary').v2;
const { CloudinaryStorage } = require('multer-storage-cloudinary');
const multer = require('multer');

cloudinary.config({
  cloud_name: process.env.CLOUDINARY_CLOUD_NAME,
  api_key: process.env.CLOUDINARY_API_KEY,
  api_secret: process.env.CLOUDINARY_API_SECRET,
});

const storage = new CloudinaryStorage({
  cloudinary: cloudinary,
  params: {
    folder: 'tinkerly_uploads',
    allowed_formats: ['jpg', 'png', 'jpeg', 'mp4', 'mov', 'webm', 'mp3', 'wav', 'aac', 'ogg', 'pdf', 'docx'],
    resource_type: 'auto',
  },
});

const parser = multer({
  storage: storage,
  limits: {
    fileSize: 100 * 1024 * 1024, // 100MB limit for video files
    fieldSize: 100 * 1024 * 1024, // 100MB limit for field values
  }
});

module.exports = { cloudinary, parser }; 