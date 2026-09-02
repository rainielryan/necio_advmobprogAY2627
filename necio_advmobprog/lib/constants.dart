import 'package:flutter_dotenv/flutter_dotenv.dart';

var host = dotenv.env['HOST'];
final cartUserId = int.tryParse(dotenv.env['USER_ID'] ?? '5') ?? 5;