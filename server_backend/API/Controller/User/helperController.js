const express = require('express');
const app = express();


const helper = require("../../Tools/RequestFunctions");
const HelperUser = require("../../Model/User/helperUser");
app.post('/setstatus' , (request , response) => {
    helper.verifyToken(request , (userID) => {
        if ( userID === null ){
            response.sendStatus(403);
        }
        else{
            let helper = new HelperUser(request.body);
            helper.setStatus(userID , request.body.status)
                .then(() => {
                    response.sendStatus(200);
                })
                .catch( (error) => {
                    response.send(error);
                } );
        }
    })
});



app.get( '/getstate' , (request , response) => {
    helper.verifyToken(request , (userId) => {
        if ( userId === null ){
            // Forbidden
            response.sendStatus(403);
        }
        else{
            let helper = new HelperUser(request.body);
            helper.getState(userId).then( (userJson) => {
                response.send(userJson);
            } )
            .catch( (error) => {
                response.send(error);
            } );
        }
    });
} );
module.exports = app;