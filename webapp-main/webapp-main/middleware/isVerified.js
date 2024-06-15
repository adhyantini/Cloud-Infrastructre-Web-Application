const db = require("../models");
const User = db.User;

exports.emailVerified = async (req, res, next) => {
    try {
        const authheader = req.headers.authorization;
        console.log(req.headers);

        if (!authheader) {
            res.status(401).send({ "message": "Please enter username/password" });
        }

        const auth = new Buffer.from(authheader.split(' ')[1],
            'base64').toString().split(':');
        const username = auth[0];

        const user = await User.findOne({
            where: {
                username: username
            }

        });
        //if user email is found, compare password with bcrypt
        if (user != null) {
            // console.log("password from client ==", password);
            // console.log("User found ===", user.dataValues.password);
            // const isSame = await bcrypt.compare(password, user.dataValues.password);

            isVerified = user.dataValues.is_verified
            if (!isVerified) {
                res.status(400).send({ "message": "Please verify your email before proceeding" });
            } else {
                next();
            }

        } else {
            return res.status(401).send({ "message": "Incorrect username or password" });
        }
    } catch (error) {
        console.log("Error during authentication =====", error);
        return res.status(503).send();
    }
};