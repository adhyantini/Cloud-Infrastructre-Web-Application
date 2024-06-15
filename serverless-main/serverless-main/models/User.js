const { Sequelize } = require('sequelize');
const sequelize = require('../conifg/config');

    const User = sequelize.define("User", {
        id: {
            type: Sequelize.UUID,
            primaryKey: true,
            defaultValue: Sequelize.UUIDV4,
      },
        username: {
          type: Sequelize.STRING,
          allowNull: false,
          unique:true,
          allowNull: false,
          validate: {
            notNull: { msg: "Username is required" },
            isEmail: true,
            notEmpty: true,
          },
        },
      
        firstName: {
          type: Sequelize.STRING,
          allowNull: false,
          validate: {
            notNull: { msg: "Firstname is required" },
            notEmpty: true,
            isAlpha: true
          },
        },
    
        lastName: {
            type: Sequelize.STRING,
            allowNull: false,
            validate: {
              notNull: { msg: "Last name is required" },
              notEmpty: true,
              isAlpha: true
            },
          },
      
        password: {
          type: Sequelize.STRING,
          allowNull: false,
          validate: {
            notNull: { msg: "Password is required" },
            notEmpty: true,
          },
        },

        token: {
          type: Sequelize.STRING,
          allowNull: true
        },
    
        is_verified: {
          type: Sequelize.BOOLEAN,
          defaultValue: false
        },
      });
     
      
      module.exports = User;
    