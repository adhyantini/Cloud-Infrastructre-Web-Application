const chai = require('chai');
const chaiHttp = require('chai-http');
const app = require('../index'); // Adjust the path according to your project structure
const expect = chai.expect;
const request = require('supertest');
const db = require("../models");
const User = db.User;
chai.use(chaiHttp);
const assert = require('assert');

describe('Testing express app routes', () => {
  describe('Testing /user route', () => {

    before(async function () {
      try {
        await db.sequelize.sync({ logging: console.log });
      } catch (error) {
        console.error('Failed to sync db:', error);
      }
    });

    after(async function () {
      // Cleanup if necessary, could be dropping tables, closing connections, etc.
      await db.sequelize.close();
    });

    // Reference: stackoverflow
    describe('Basic Addition Test', function () {
      it('Should return the result of the addition', function (done) {
        assert.strictEqual(10 + 10, 20);
        done();
      });
    });




    // describe('POST /v1/user', () => {
    //   it('should Create a user', (done) => {
    //     let userInfo = {
    //       email: "testuser@example.com",
    //       firstName: "Test",
    //       lastName: "User",
    //       password: "password123"
    //     };
    //     chai.request(app)
    //       .post('/v1/user')
    //       .send(userInfo)
    //       .end((err, res) => {
    //         expect(res).to.have.status(201);
    //         expect(res.body).to.be.a('object');
    //         expect(res.body).to.have.property('email');
    //         expect(res.body).to.have.property('firstName');
    //         expect(res.body).to.have.property('lastName');
    //         expect(res.body).to.have.property('id');
    //         // Add any more assertions here as per your response structure
    //         done();
    //       });
    //   });
    // });

    describe('GET /v2/user', () => {
      let createUser;
      before(async () => {
        // CREATING NEW USER
        let userInfo = {
          username: "testuser@example.com",
          firstName: "Test",
          lastName: "User",
          password: "password123"
        };
        // Making post request
        const creatUserResponse = await chai.request(app)
          .post('/v2/user')
          .send(userInfo);
        console.log("create user resp ===", creatUserResponse);
        expect(creatUserResponse).to.have.status(201);
        createUser = creatUserResponse.body

        User.update({
          is_verified: true
        }, {
          where: { id: createUser.id }
        });
      })

      after(async () => {
        console.log("DB USER BODY =====", createUser.id)
        if (createUser) {
          await User.destroy({ where: { id: createUser.id } });
        }
      })
      it('GET user should successfully return item', (done) => {
        chai.request(app)
          .get('/v2/user/self')
          .set('Authorization', 'Basic dGVzdHVzZXJAZXhhbXBsZS5jb206cGFzc3dvcmQxMjM=') // Setting a single header
          .end((err, res) => {
            expect(res).to.have.status(200);
            done();
          });
      });
    });

    describe('PUT /v2/user', () => {
      let createUser;
      before(async () => {
        let userInfo = {
          username: "testuser@example.com",
          firstName: "Test",
          lastName: "User",
          password: "password123"
        };
        // Making post request
        const creatUserResponse = await chai.request(app)
          .post('/v2/user')
          .send(userInfo);
        expect(creatUserResponse).to.have.status(201);
        createUser = creatUserResponse.body
        User.update({
          is_verified: true
        }, {
          where: { id: createUser.id }
        });

      })

      after(async () => {
        console.log("DB USER BODY =====", createUser.id)
        if (createUser) {
          await User.destroy({ where: { id: createUser.id } });
        }
      })
      it('should Update a user', (done) => {
        let userInfo = {
          firstName: "Test",
          lastName: "User",
          password: "password123"
        };
        chai.request(app)
          .put('/v2/user/self')
          .set('Authorization', 'Basic dGVzdHVzZXJAZXhhbXBsZS5jb206cGFzc3dvcmQxMjM=')
          .send(userInfo)
          .end((err, res) => {
            expect(res).to.have.status(204);
            done();
          });
      });
    });
  });
});