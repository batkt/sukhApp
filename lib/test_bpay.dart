import 'package:http/http.dart' as http;
void main() async {
  var url1 = Uri.parse('https://api.bpay.mn/v1/api/billing/address/84afecf6-2b7d-4bde-b204-43283f781d08/54');
  var res = await http.get(url1);
  print('v1: ${res.statusCode}');
  print(res.body);

  var url2 = Uri.parse('https://api.bpay.mn/api/billing/address/84afecf6-2b7d-4bde-b204-43283f781d08/54');
  var res2 = await http.get(url2);
  print('root: ${res2.statusCode}');
  print(res2.body);
}
