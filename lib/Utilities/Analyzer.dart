import 'dart:convert';
import 'package:fake_news_detector/Utilities/Networking.dart';
import 'package:rake/rake.dart';
import 'package:document_analysis/document_analysis.dart';

class Analyzer {
  static String titleToSend;
  static String imageLinkToSend;
  static String siteNameToSend;
  static String snippetToSend;
  Networking obj = Networking();
  Future query(String q) async {
    Rake rake = Rake();
    q = rake.rank(q).join(' ');
    q = q.replaceAll('-', ' ');
    q = q.replaceAll(',', ' ');
    q = q.replaceAll('/', ' ');
    q = q.replaceAll(':', ' ');
    q = q.replaceAll('.', ' ');
    q = q.replaceAll('_', ' ');

    var rawData = await obj.getData(q);

    var decodeJson1 = await json.decode(rawData);
    titleToSend = decodeJson1['items'][1]['title'];
    snippetToSend = decodeJson1['items'][1]['snippet'];
    try {
      imageLinkToSend =
          decodeJson1['items'][1]['pagemap']['metatags'][0]['og:image'];
      siteNameToSend =
          decodeJson1['items'][1]['pagemap']['metatags'][0]['og:site_name'];
    } catch (e) {
      print(e);
    }
    List<String> wordSet = [
      'falsehood',
      'lie',
      'forgery',
      'fraud',
      'phoney',
      'pirate',
      'false',
      'pseudo',
      'fakey',
      'cheat',
      'bluff',
      'fake',
      'viral',
      'hoax',
      'rumour'
    ];

    int totalMatched = 0;
    int fakeMatched = 0;

    for (int i = 0; i < 10; i++) {
      String wordSnip, wordTitle, wordUrl;
      if (i < 10) {
        wordSnip = decodeJson1['items'][i]['snippet'];
        wordTitle = decodeJson1['items'][i]['title'];
        wordUrl = decodeJson1['items'][i]['formattedUrl'];
      }
      // else {
      //   wordSnip = decodeJson2['items'][i - 10]['snippet'];
      //   wordTitle = decodeJson2['items'][i - 10]['title'];
      //   wordUrl = decodeJson2['items'][i - 10]['formattedUrl'];
      // }
      String rakeWordSnip = rake.rank(wordSnip.toString()).toString();
      double ratioSnip =
          wordFrequencySimilarity(rakeWordSnip, rake.rank(q).toString());

      String rakeWordTitle = rake.rank(wordTitle.toString()).toString();
      double ratioTitle =
          wordFrequencySimilarity(rakeWordTitle, rake.rank(q).toString());

      wordUrl = wordUrl.replaceAll('-', ' ');
      wordUrl = wordUrl.replaceAll(',', ' ');
      wordUrl = wordUrl.replaceAll('/', ' ');
      wordUrl = wordUrl.replaceAll(':', ' ');
      wordUrl = wordUrl.replaceAll('.', ' ');
      wordUrl = wordUrl.replaceAll('_', ' ');

      if (ratioSnip >= 0.30 || ratioTitle >= 0.35) {
        // print('Ratios are for $i : $ratioSnip and $ratioTitle');
        // print('Rake for $i are : $rakeWordSnip and $rakeWordTitle');
        // print('');
        totalMatched++;

        for (int i = 0; i < wordSet.length; i++) {
          if (rakeWordSnip.contains(wordSet[i]) ||
              rakeWordTitle.contains(wordSet[i]) ||
              wordUrl.contains(wordSet[i])) {
            fakeMatched++;
            break;
          }
        }
      }
      // print('$i     $percentage');
    }

    int percentage =
        (fakeMatched.toDouble() / totalMatched.toDouble() * 100.0).toInt();

    // Display Link not required

    // Formatted url only to check fake

    return percentage;
  }
}
