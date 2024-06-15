const express = require("express");
const cors = require("cors");
require('dotenv').config()
const app = express();
const bunyan = require('bunyan');
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

const db = require("./models");
db.sequelize.sync({ alter: true })
  .then(() => {
    log.warn('Db not yet synced!');
    console.log("Synced db.");
  })
  .catch((err) => {
    log.error('Db sync error: ', err);
    console.log("Failed to sync db: " + err.message);
  });

app.use(express.json());

// parse requests of content-type - application/x-www-form-urlencoded
app.use(express.urlencoded({ extended: true }));

app.get("/", (req, res) => {
  res.json({ message: "Welcome" });
});

require("./routes/routes")(app);

module.exports = app;