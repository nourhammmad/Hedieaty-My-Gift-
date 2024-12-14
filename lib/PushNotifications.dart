import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:googleapis/monitoring/v3.dart';
import 'package:http/http.dart' as http;
import 'package:googleapis_auth/auth_io.dart' as auth;
import 'package:googleapis/servicecontrol/v1.dart' as servicecontrol;

class PushNotifications {
  static Future<String> getAccessToken() async{
    final serviceAccountJSON={

        "type": "service_account",
        "project_id": "hedeaty",
        "private_key_id": "520ccaf82d69d49a7b16a8f9587445a7e97731eb",
        "private_key": "-----BEGIN PRIVATE KEY-----\nMIIEvgIBADANBgkqhkiG9w0BAQEFAASCBKgwggSkAgEAAoIBAQDBVPennFNSfeG3\nWg9ImXyEmZWMtj2cc36+TvFN3AxZk960txMpC+14sfg+u2FkuNd9Uq+h5yBrG3m6\n9LXlms7OzOB1z0Scw7UOX1uzv4kqwouYxpactsEWgWHx2nfndH/vtIAwSB42dKJn\nlX9IN6IRFYv5VW7eOOCvarDc0TAous4+SgF1w9MTRmpr3Rk1aNDRtzZOmE/s6h/g\nFmN+N7ZEhDdOZfJsadeUkSYak5uvIj6Fxfm3dENibYUfgT3kqHum2pJRlJhIcPxn\nQGMFcKjo/RWPOq7IEwRcj4yz95Fvd/ZCfOh1IHyQh7qZWshn+iqX8IKlxinvoQ8r\ndFRHwzXXAgMBAAECggEASKo/dUOn+6rtwiT69p4d85boY12B9cJhQnVYdBu/lpGi\nFMl0zao6hPFbbXSvbBSfhe6krdU51Zgbnl3o2lZf4dGWkiEn2EYk0LSduodEroo1\nvuPxaxCzrVpO7oDfLWMXzQhKYBtTI8Od4RILJ6ElbIdtN3dZdvPo23Xd6PlFQSEi\nMGikNYvNxZebI+jA7Jq1dWdsEDByYfvSN/ZEiGsoEq9NgQfprLKox6skGFL/G8w6\nLwglAPxUmJBFWIiCNk61IPC00kusd+7h2eSwhv1k/KbKZMj7g1SDF6pLPbn5De8r\nOL6nUBD/jjGiZFkfavNgnFAMILLw/CPy5UuPRPb9lQKBgQDheunnsAJh7OB4pfn2\nXJvpEnAdtL8QwjiQ3CYduXHapjna3UlodjrEBOGbGL1Qlh/8u+6fn7l4PqsPCbVC\nshSa4D2BZ2lOEWrO98+8wweiALtDOKy8DImYrYmAgYMOSapr3l1psEw8hhqd69XK\nqWYJehQRaZ3cmnVl3E1gBDQeqwKBgQDbgBbR64sq6VjeLrW6BDWrQT7sKl7UWxM1\nAX2/2cJVttrm3sA7vUJa8M1DerGWNq6QbYjNj2zKKfMsUxBPqVuEyFx6OtknL1sW\ntBV5dvZOfKxmKK/wmUrXYymqJsV8E4uwux9KvDMqhT787ZXpvieXf65zIQ1nVvrF\n/EqB1YHVhQKBgQCplDCgwF46WdXEx0eEQsg7dVN+8/YS24+BWyELj/IR+Jxgf7b6\n6pht3iHy7JtNJWsvQARKZu0tgyxRpgJ+A8K9bFK1pRmsziqfN/8zvxZZf+VWvCQl\nVeSSQEm+rSjssPiMIfPtTds4Vb9k7/6daePE0tyO7/j69eu/TP2gbejo+wKBgFP4\n/MHySptwCf91/y/azG1n2Jqg2waCkSaGG4V52U7RVY1dSk2QagJAfUaDecztvnqi\nbOO3KvdsdQtP+71+HPT/ceGRAeJry300B8MgL7p3F709c5GoE2mzFg1yJ7r//0Dt\nVVtSBIEP2LkKa3+wr5TV0/dXfbk7HVUA38Ar3i/BAoGBANDKUYuLEmIHYUVzrAkH\noKlxp3deGU64SzwzAKsaGt9++noU0NBcbP9v+sk3/vgeMJWzerhWnBs1PV34qvl0\neEKkTHZo5N6Cidqjr/z3nztFhKjTfdNxaN6Rh6khrYBIdKCd5jzl99LsbTgZwjMF\nEaP8Ylld5lHuDEUllmgXjL0P\n-----END PRIVATE KEY-----\n",
        "client_email": "hedeaty@appspot.gserviceaccount.com",
        "client_id": "107336108565009751785",
        "auth_uri": "https://accounts.google.com/o/oauth2/auth",
        "token_uri": "https://oauth2.googleapis.com/token",
        "auth_provider_x509_cert_url": "https://www.googleapis.com/oauth2/v1/certs",
        "client_x509_cert_url": "https://www.googleapis.com/robot/v1/metadata/x509/hedeaty%40appspot.gserviceaccount.com",
        "universe_domain": "googleapis.com"
    };
    List<String> scopes=[
      "https://www.googleapis.com/auth/firebase.messaging"
    ];
    http.Client client=await auth.clientViaServiceAccount(
      auth.ServiceAccountCredentials.fromJson(serviceAccountJSON),
      scopes,
    );
    auth.AccessCredentials credentials=await auth.obtainAccessCredentialsViaServiceAccount(
      auth.ServiceAccountCredentials.fromJson(serviceAccountJSON),
      scopes,
      client
    );
  client.close();
  return credentials.accessToken.data;
  }
  static SendNotificationToPledgedFriend(String deviceToken,BuildContext context,String pledgedGiftId,String PledgedGiftName,String PledgedGiftEventName,String PledgerName) async{
    final String serverAccessTokenKey= await getAccessToken();
    String endptFCM='https://fcm.googleapis.com/v1/projects/hedeaty/messages:send';
    final Map<String,dynamic> message={
      'message':{
        'token':deviceToken,
        'notification':
            {
              'title':"Gift Pledged Alert!",
              'body':"Gift: $PledgedGiftName for Event: $PledgedGiftEventName was pledged by $PledgerName",
            },
        'data':{
          'pledgedGiftId':pledgedGiftId
        }
      }
    };
    final http.Response response= await http.post(Uri.parse(endptFCM),
    headers:<String,String>{
      'Content-Type':'application/json',
      'Authorization':'Bearer $serverAccessTokenKey'
    },
    body:jsonEncode(message),);
    if(response.statusCode == 200){
      print("Notification Sent Successfully");
    }else{
      print("Notification not sent");
    }

  }
}