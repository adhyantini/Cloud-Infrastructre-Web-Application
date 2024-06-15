const db = require("../models");
const User = db.User;
const bcrypt = require("bcrypt")
const Op = db.sequelize.Op;
const dbConfig = require("../config/config");
const bunyan = require('bunyan');
const { PubSub } = require('@google-cloud/pubsub');
const pubSubClient = new PubSub();
const topicNameOrId = 'projects/dev-gcp-414621/topics/verify_email';
const severityMap = {
  10: 'DEBUG',    // Bunyan's TRACE level
  20: 'DEBUG',    // Bunyan's DEBUG level
  30: 'INFO',     // Bunyan's INFO level
  40: 'WARNING',  // Bunyan's WARN level
  50: 'ERROR',    // Bunyan's ERROR level
  60: 'CRITICAL', // Bunyan's FATAL level
};
const log = bunyan.createLogger({
  name: 'webapp',
  streams: [
    {
      path: '/var/log/webapp.log'  // Specify your log file path here
    }
  ],
  serializers: bunyan.stdSerializers,
  // Extend the log record using the `serializers` field
  levelFn: (level, levelName) => {
    return { 'severity': severityMap[level] };
  }
});

const originalWrite = log._emit;
log._emit = function (rec, noemit) {
  rec.severity = severityMap[rec.level];
  originalWrite.call(this, rec, noemit);
};

exports.methodNotAllowed = (req, res, next) => res.status(405).send();


exports.ping = (req, res) => {
  try {
    const header = req.headers['content-type'];
    console.log("req paramsss", req.params);
    if (header || Object.keys(req.query).length > 0) {
      res.status(400).send();
    }
    db.sequelize.authenticate().then(() => {
      console.log("Connection has been established successfully.");
      log.info('Database connection has been established successfully');
      res.status(200).send();
    }).catch(err => {
      res.status(503).send();
      console.error('Authentication error', err);
      log.error('Authentication error', err);
    });
  } catch (error) {
    res.status(503).send();
    console.error("Unable to connect to the database:", error);
    log.error('Unable to connect to the database:', error);
  }

};

async function publishMessage(dataBuffer) {
  try {
    console.log("Insideeeeee publish message!!!!!");
    const messageId = await pubSubClient
      .topic(topicNameOrId)
      .publishMessage({ data: dataBuffer });
    console.log(`Message ${messageId} published.`);
  } catch (error) {
    console.error(`Received error while publishing: ${error.message}`);
    log.error("Error occcured while trying to publish a message", error, " sdfsdf", error.message);
    process.exitCode = 1;
  }
}

// Create User
exports.create = (req, res) => {

  if (Object.keys(req.query).length > 0) {
    return res.status(400).send();
  }

  if (!req.body.username || !req.body.firstName || !req.body.lastName || !req.body.password) {
    res.status(400).send({
      message: "Either password, username, or name body missing!"
    });
    log.error('Missing field error');
    return;
  }

  const hashedPassword = bcrypt.hashSync(req.body.password, 10);

  const user = {}

  for (const key in req.body) {
    user[key] = req.body[key];
    if (key == "password") {
      user[key] = hashedPassword;
    }
  }
  // const token = crypto.randomBytes(32).toString('hex');
  // console.log("TOKENNNNNNN", token);
  // user.token = token;

  console.log("DB HOSTTTTT ======", dbConfig.HOST);
  console.log("DB USER ======", dbConfig.USER);
  console.log("DB PASSWORD ======", dbConfig.PASSWORD);
  console.log("DB NAME ======", dbConfig.DB);
  // Save User in the database
  User.create(user)
    .then(data => {
      res.status(201).send({
        id: data.id,
        username: data.username,
        firstName: data.firstName,
        lastName: data.lastName,
        account_created: data.createdAt,
        account_updated: data.updatedAt
      });
      log.info('User with user id created successfully', { userId: data.id });
      console.log("User with user id created successfully");
      log.info('User details as follows', { userId: data.id }, { username: data.username }, { firstName: data.firstName }, { lastName: data.lastName });
      objToPublish = {};
      objToPublish.userID = data.id;
      objToPublish.emailID = data.username;
      objToPublish.firstName = data.firstName;
      objToPublish.lastName = data.lastName;
      console.log("OBJECT TO SEND TO PUBSUB", objToPublish);

      const dataBuffer = Buffer.from(JSON.stringify(objToPublish));
      console.log("DATA BUFFER TO SEND TO PUBSUB", dataBuffer);
      console.log("Before publish message!!!!!");
      publishMessage(dataBuffer)
        .then((messageId) => { console.log(`Message ${messageId} published.`); }).catch(err => {
          console.log("Error from pub sub message part", err);
          log.error("Error from pub sub message part", err);
        });
      console.log("After publish message!!!!!");

    })
    .catch(err => {
      console.log("DB HOSTTTTT in catch block ======", dbConfig.HOST);
      console.log("DB User in catch block ======", dbConfig.USER);
      console.log("DB password in catch block ======", dbConfig.PASSWORD);
      console.log("DB name in catch block ======", dbConfig.DB);
      console.log("Errrrorrrr issss", err.name, "THE MESSAGEEEE ISSSSSSS", err.message);

      // Map email already exists error thrown from DB to status code 400
      if (err.name === 'SequelizeUniqueConstraintError') {
        log.error('User could not be created as user already exists');
        res.status(400).json({
          message: "A user with this email already exists.",
          error: err.errors.map(e => e.message),
        });
      }

      // Map incorrect email format validation error thrown from DB to status code 400
      if (err.name === 'SequelizeValidationError' && err.message == "Validation error: Validation isEmail on email failed") {
        log.error('User could not be created as email is not valid');
        res.status(400).json({
          message: "Invalid Email format",
        });
      }

      //Map other unkown server errors to status code 500
      log.error('User could not be created as error unknown');
      res.status(400).json({

      });
    });
};

// Find user by ID
exports.findOne = (req, res) => {
  const header = req.headers['content-type'];
  console.log("req paramsss", req.params);
  if (header || Object.keys(req.query).length > 0) {
    res.status(400).send();
  }
  const authheader = req.headers.authorization;
  const auth = new Buffer.from(authheader.split(' ')[1],
    'base64').toString().split(':');
  const username = auth[0];
  User.findOne({
    where: {
      username: username
    }
  }).then(data => {
    if (data) {
      log.info('User with user id logged in and tried to access user details', { userId: data.id });
      res.send({
        id: data.id,
        username: data.username,
        firstName: data.firstName,
        lastName: data.lastName,
        createdAt: data.createdAt,
        updatedAt: data.updatedAt
      });
    } else {
      res.status(404).send({
        message: `Cannot find User with id=${id}.`
      });
    }
  }).catch(err => {
    res.status(503).send({
      message: "Error retrieving User"
    });
  });
};

exports.findTokenAndVerify = (req, res) => {
  const token = req.params.token;
  User.findOne({
    where: {
      token: token
    }
  }).then(data => {
    if (data) {
      log.info('User with user id logged in and tried to access user details', { userId: data.id });
      createdTime = data.createdAt;
      const timestampDate = new Date(createdTime);
      const now = new Date();
      const difference = now - timestampDate;
      const differenceInMinutes = difference / 1000 / 60;
      if (differenceInMinutes > 2) {
        console.log('More than 2 minutes have passed.');
        log.info("The user is set to not verified as more than 2 minutes have passed");
        return res.status(400).send("Link has expired. Please request for a new one");
      } else {
        User.update({
          is_verified: true
        }, {
          where: { token: token }
        });

        log.info("The user is set to verified");
        return res.status(200).send("Email Verified Successfully");
      }

    } else {
      res.status(404).send({
        message: `Cannot find User with id=${id}.`
      });
    }
  }).catch(err => {
    res.status(503).send({
      message: "Error retrieving User"
    });
  });
};

// Update a user
exports.update = (req, res) => {
  if (Object.keys(req.query).length > 0) {
    return res.status(400).send();
  }

  if (Object.keys(req.body).length > 3) {
    return res.status(400).send({
      message: "Can only update firstName, lastName and password fields."
    });
  }

  if (!req.body.firstName || !req.body.lastName || !req.body.password) {
    res.status(400).send({
      message: "Either password, username, or name body missing!"
    });
    return;
  }

  const authheader = req.headers.authorization;
  const auth = new Buffer.from(authheader.split(' ')[1],
    'base64').toString().split(':');
  const username = auth[0];

  if (req.body.username || req.body.account_created || req.body.account_updated) {
    return res.status(400).send({
      message: "Invalid update field"
    });
  }

  console.log("Request body from the client side ====", req.body);
  console.log("Emailllll ==== ", username)
  if (req.body && req.body.password) {
    req.body.password = bcrypt.hashSync(req.body.password, 10);
  }

  User.update(req.body, {
    where: { username: username }
  })
    .then(num => {
      if (num == 1) {
        log.info('User with user name updated successfully', { userId: username });
        res.status(204).send();
      } else {
        log.error('User could not be updated due to following error', { error: 'Maybe User was not found or req.body is empty!' })
        res.status(400).json({
          message: `Cannot update User with username=${username}. Maybe User was not found or req.body is empty!`
        });
      }
    })
    .catch(err => {

      // Map empty fields not allowed to 400 status code
      if (err.name === 'SequelizeValidationError' && err.errors[0].validatorKey == "notEmpty") {
        log.error('User could not be updated due to following error', { error: 'Empty fields not allowed! Please enter a value' })
        res.status(400).json({
          message: "Empty fields not allowed! Please enter a value",
        });
      }

      res.status(503).send({
        message: "Error updating User"
      });
    });
};
