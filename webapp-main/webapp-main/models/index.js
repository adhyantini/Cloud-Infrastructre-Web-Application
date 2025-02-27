const dbConfig = require("../config/config.js");
const Sequelize = require("sequelize");


const sequelize = new Sequelize(dbConfig.DB, dbConfig.USER, dbConfig.PASSWORD, {
  host: dbConfig.HOST,
  dialect: dbConfig.dialect,
  operatorsAliases: false,

  pool: {
    max: dbConfig.pool.max,
    min: dbConfig.pool.min,
    acquire: dbConfig.pool.acquire,
    idle: dbConfig.pool.idle
  }
});
const User = require('./User.js')(sequelize, Sequelize.DataTypes);
const db = {};

db.Sequelize = Sequelize;
db.sequelize = sequelize;
db.User = User;
module.exports = db;