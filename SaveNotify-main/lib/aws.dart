import 'package:amazon_cognito_identity_dart_2/cognito.dart';
import 'package:dart_jsonwebtoken/dart_jsonwebtoken.dart';
import 'package:flutter/material.dart';

class Aws{

  String? token;
  String? newToken;
  getToken(String user, String pass)async{
    final userPool = CognitoUserPool(
  'us-east-1_WN7mX5v6o',
  '556ootgckn7idfhepo7c0up52g',
  clientSecret: "\$2b\$10\$nRhtu2/1Sn34gPorI8IA9e"
);
final cognitoUser = CognitoUser('wsegurar@gmail.com', userPool);
final authDetails = AuthenticationDetails(
  username: user,//'wsegurar@gmail.com',
  password: pass//'Lima1234*',
);
CognitoUserSession? session;
try {
  session = await cognitoUser.authenticateUser(authDetails);
} on CognitoUserNewPasswordRequiredException catch (e) {
  // handle New Password challenge
} on CognitoUserMfaRequiredException catch (e) {
  // handle SMS_MFA challenge
} on CognitoUserSelectMfaTypeException catch (e) {
  // handle SELECT_MFA_TYPE challenge
} on CognitoUserMfaSetupException catch (e) {
  // handle MFA_SETUP challenge
} on CognitoUserTotpRequiredException catch (e) {
  // handle SOFTWARE_TOKEN_MFA challenge
} on CognitoUserCustomChallengeException catch (e) {
  // handle CUSTOM_CHALLENGE challenge
} on CognitoUserConfirmationNecessaryException catch (e) {
  // handle User Confirmation Necessary
} on CognitoClientException catch (e) {
  // handle Wrong Username and Password and Cognito Client
}catch (e) {
  print(e);
}
token = session?.getAccessToken().getJwtToken();
// print(session?.getAccessToken().getJwtToken());
  }

  Future<String?> singin(String user, String pass)async{
    await getToken(user, pass);
    final payload = JWT.decode(token!);
    newToken = JWT(payload.payload).sign(SecretKey('\$2b\$10\$nRhtu2/1Sn34gPorI8IA9e'));
    return newToken;
    // print(payload.payload);
  }
}