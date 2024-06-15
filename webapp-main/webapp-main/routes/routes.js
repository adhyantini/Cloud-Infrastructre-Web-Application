module.exports = app => {
    const healthCheck = require("../controllers/controller.js");
    const auth = require("../middleware/auth.js");
    const verificationCheck = require("../middleware/isVerified.js");
  
    var router = require("express").Router();


    router.use("/v1/healthz", (req, res, next) => {
      if(req.method != "GET"){
        res.status(405).send();
      } else{
        res.setHeader("cache-control", "no-cache, no-store, must-revalidate");
        next();
      }
    })

     router.get("/v1/healthz", healthCheck.ping);
     router.get("/v1/verify/:token", healthCheck.findTokenAndVerify);
     router.post("/v2/user", healthCheck.create).all("/user", (req,res)=>{
          res.status(405).send();
     });
     router.get("/v2/user/self", auth.authentication, verificationCheck.emailVerified ,healthCheck.findOne);
     router.put("/v2/user/self", auth.authentication, verificationCheck.emailVerified ,healthCheck.update).all("/user/self", (req,res)=>{
      res.status(405).send();
 });; 

    app.use(router);
  };
