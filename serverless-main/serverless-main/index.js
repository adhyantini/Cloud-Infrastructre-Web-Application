const { PubSub } = require('@google-cloud/pubsub');
const bunyan = require('bunyan');
const Mailgun = require('mailgun.js');
const FormData = require('form-data');
const mailgun = new Mailgun(FormData);
const mg = mailgun.client({ username: 'api', key: process.env.MAILGUN_API_KEY || 'key-yourkeyhere' });
const sequelize = require("./conifg/config");
const User = require("./models/User");
const crypto = require('crypto');

exports.processPubSubMessage = async (pubSubEvent) => {
  const log = bunyan.createLogger({
    name: 'webapp',
    streams: [
      {
        level: 'info',
        stream: process.stdout,
      },
    ],
  });

  // Decode the Pub/Sub message
  const messageString = Buffer.from(pubSubEvent.data, 'base64').toString();
  const message = JSON.parse(messageString);
  // Log the message
  log.info({ message: message }, 'Received message');

  console.log(`Processed message: ${messageString}`);
  const token = crypto.randomBytes(32).toString('hex');

  log.info("Going to connect to sequelise now");
  await sequelize.authenticate();
  log.info("Sequelise connection has been established successfully!");
  const userID = message.userID;
  const emailID = message.emailID;
  const user = await User.findByPk(userID);
  log.info("User object fetched ===", user);
  if (user) {
    try{
        const [affectedRows] = await User.update({ token: token }, { where: { username: emailID } });
    if (affectedRows > 0) {
      log.info("Token has been successfully updated.");
    } else {
      log.info("Token update failed. No rows affected.");
    }
    }catch(err){
      log.info("Update user error is --->", err);
    }
    log.info("A token has been generetaed and saved in the database!", token);
  const firstName = message.firstName;
  const lastName = message.lastName;
  const emailData = {
    from: 'Adhyantini Bogawat <no-reply@adhyantini.me>',
    to: emailID,
    subject: 'Verify your email address',
    html: `Hi ${firstName} ${lastName}! <br><br> Please verify your email address by clicking the link below: https://adhyantini.me.:443/v1/verify/${token}`,
  };
    log.info("A token has been generetaed and saved in the database!");

    try {
    const msg = await mg.messages.create('adhyantini.me', emailData);
    log.info("Sent mail", msg);
    console.log(msg);
  } catch (err) {
    log.info("ERRROOOORRRRRRRR", err);
  }
  } else {
    log.error("The user does not exist in the table");
  }
  log.info("The entire process has been completed!!");
};