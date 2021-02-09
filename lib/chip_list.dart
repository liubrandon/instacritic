import 'package:flag/flag.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:instacritic/constants.dart';
import 'package:instacritic/tag.dart';
import 'package:pointer_interceptor/pointer_interceptor.dart';
import 'package:provider/provider.dart';
import 'instagram_repository.dart';
import 'package:iso_2_emoji_flag/iso_2_emoji_flag.dart';
import 'sort_filter.dart';

class ChipList extends StatefulWidget {
  final void Function(String, {Tag tag}) updateCurrentReviews;
  final TextEditingController textController;
  final ScrollController scrollController;
  const ChipList(this.updateCurrentReviews, this.textController, this.scrollController);
  @override
  _ChipListState createState() => _ChipListState();
}

class _ChipListState extends State<ChipList> {
  static final countryCodes = {'Afghanistan': 'AF','Åland Islands': 'AX','Albania': 'AL','Algeria': 'DZ','American Samoa': 'AS','Andorra': 'AD','Angola': 'AO','Anguilla': 'AI','Antarctica': 'AQ','Antigua and Barbuda': 'AG','Argentina': 'AR','Armenia': 'AM','Aruba': 'AW','Australia': 'AU','Austria': 'AT','Azerbaijan': 'AZ','Bahamas': 'BS','Bahrain': 'BH','Bangladesh': 'BD','Barbados': 'BB','Belarus': 'BY','Belgium': 'BE','Belize': 'BZ','Benin': 'BJ','Bermuda': 'BM','Bhutan': 'BT','Bolivia (Plurinational State of)': 'BO','Bonaire, Sint Eustatius and Saba': 'BQ','Bosnia and Herzegovina': 'BA','Botswana': 'BW','Bouvet Island': 'BV','Brazil': 'BR','British Indian Ocean Territory': 'IO','Brunei Darussalam': 'BN','Bulgaria': 'BG','Burkina Faso': 'BF','Burundi': 'BI','Cabo Verde': 'CV','Cambodia': 'KH','Cameroon': 'CM','Canada': 'CA','Cayman Islands': 'KY','Central African Republic': 'CF','Chad': 'TD','Chile': 'CL','China': 'CN','Christmas Island': 'CX','Cocos (Keeling) Islands': 'CC','Colombia': 'CO','Comoros': 'KM','Congo': 'CG','Congo, Democratic Republic of the': 'CD','Cook Islands': 'CK','Costa Rica': 'CR','Côte d\'Ivoire': 'CI','Croatia': 'HR','Cuba': 'CU','Curaçao': 'CW','Cyprus': 'CY','Czechia': 'CZ','Denmark': 'DK','Djibouti': 'DJ','Dominica': 'DM','Dominican Republic': 'DO','Ecuador': 'EC','Egypt': 'EG','El Salvador': 'SV','Equatorial Guinea': 'GQ','Eritrea': 'ER','Estonia': 'EE','Eswatini': 'SZ','Ethiopia': 'ET','Falkland Islands (Malvinas)': 'FK','Faroe Islands': 'FO','Fiji': 'FJ','Finland': 'FI','France': 'FR','French Guiana': 'GF','French Polynesia': 'PF','French Southern Territories': 'TF','Gabon': 'GA','Gambia': 'GM','Georgia': 'GE','Germany': 'DE','Ghana': 'GH','Gibraltar': 'GI','Greece': 'GR','Greenland': 'GL','Grenada': 'GD','Guadeloupe': 'GP','Guam': 'GU','Guatemala': 'GT','Guernsey': 'GG','Guinea': 'GN','Guinea-Bissau': 'GW','Guyana': 'GY','Haiti': 'HT','Heard Island and McDonald Islands': 'HM','Holy See': 'VA','Honduras': 'HN','Hong Kong': 'HK','Hungary': 'HU','Iceland': 'IS','India': 'IN','Indonesia': 'ID','Iran (Islamic Republic of)': 'IR','Iraq': 'IQ','Ireland': 'IE','Isle of Man': 'IM','Israel': 'IL','Italy': 'IT','Jamaica': 'JM','Japan': 'JP','Jersey': 'JE','Jordan': 'JO','Kazakhstan': 'KZ','Kenya': 'KE','Kiribati': 'KI','Korea (Democratic People\'s Republic of)': 'KP','South Korea': 'KR','Kuwait': 'KW','Kyrgyzstan': 'KG','Lao People\'s Democratic Republic': 'LA','Latvia': 'LV','Lebanon': 'LB','Lesotho': 'LS','Liberia': 'LR','Libya': 'LY','Liechtenstein': 'LI','Lithuania': 'LT','Luxembourg': 'LU','Macao': 'MO','Madagascar': 'MG','Malawi': 'MW','Malaysia': 'MY','Maldives': 'MV','Mali': 'ML','Malta': 'MT','Marshall Islands': 'MH','Martinique': 'MQ','Mauritania': 'MR','Mauritius': 'MU','Mayotte': 'YT','Mexico': 'MX','Micronesia (Federated States of)': 'FM','Moldova, Republic of': 'MD','Monaco': 'MC','Mongolia': 'MN','Montenegro': 'ME','Montserrat': 'MS','Morocco': 'MA','Mozambique': 'MZ','Myanmar': 'MM','Namibia': 'NA','Nauru': 'NR','Nepal': 'NP','Netherlands': 'NL','New Caledonia': 'NC','New Zealand': 'NZ','Nicaragua': 'NI','Niger': 'NE','Nigeria': 'NG','Niue': 'NU','Norfolk Island': 'NF','North Macedonia': 'MK','Northern Mariana Islands': 'MP','Norway': 'NO','Oman': 'OM','Pakistan': 'PK','Palau': 'PW','Palestine, State of': 'PS','Panama': 'PA','Papua New Guinea': 'PG','Paraguay': 'PY','Peru': 'PE','Philippines': 'PH','Pitcairn': 'PN','Poland': 'PL','Portugal': 'PT','Puerto Rico': 'PR','Qatar': 'QA','Réunion': 'RE','Romania': 'RO','Russian Federation': 'RU','Rwanda': 'RW','Saint Barthélemy': 'BL','Saint Helena, Ascension and Tristan da Cunha': 'SH','Saint Kitts and Nevis': 'KN','Saint Lucia': 'LC','Saint Martin (French part)': 'MF','Saint Pierre and Miquelon': 'PM','Saint Vincent and the Grenadines': 'VC','Samoa': 'WS','San Marino': 'SM','Sao Tome and Principe': 'ST','Saudi Arabia': 'SA','Senegal': 'SN','Serbia': 'RS','Seychelles': 'SC','Sierra Leone': 'SL','Singapore': 'SG','Sint Maarten (Dutch part)': 'SX','Slovakia': 'SK','Slovenia': 'SI','Solomon Islands': 'SB','Somalia': 'SO','South Africa': 'ZA','South Georgia and the South Sandwich Islands': 'GS','South Sudan': 'SS','Spain': 'ES','Sri Lanka': 'LK','Sudan': 'SD','Suriname': 'SR','Svalbard and Jan Mayen': 'SJ','Sweden': 'SE','Switzerland': 'CH','Syrian Arab Republic': 'SY','Taiwan, Province of China': 'TW','Tajikistan': 'TJ','Tanzania, United Republic of': 'TZ','Thailand': 'TH','Timor-Leste': 'TL','Togo': 'TG','Tokelau': 'TK','Tonga': 'TO','Trinidad and Tobago': 'TT','Tunisia': 'TN','Turkey': 'TR','Turkmenistan': 'TM','Turks and Caicos Islands': 'TC','Tuvalu': 'TV','Uganda': 'UG','Ukraine': 'UA','United Arab Emirates': 'AE','United Kingdom of Great Britain and Northern Ireland': 'GB','United States of America': 'US','United States Minor Outlying Islands': 'UM','Uruguay': 'UY','Uzbekistan': 'UZ','Vanuatu': 'VU','Venezuela (Bolivarian Republic of)': 'VE','Viet Nam': 'VN','Virgin Islands (British)': 'VG','Virgin Islands (U.S.)': 'VI','Wallis and Futuna': 'WF','Western Sahara': 'EH','Yemen': 'YE','Zambia': 'ZM','Zimbabwe': 'ZW',};
  bool isMobile;

  @override
  Widget build(BuildContext context) {
    List<Tag> tags = Provider.of<InstagramRepository>(context,listen:false).allTagsSorted.keys.toList();
    isMobile = MediaQuery.of(context).size.width < Constants.mobileWidth;
    return PointerInterceptor( // Bless
      child: ListView(
        controller: widget.scrollController,
        physics: AlwaysScrollableScrollPhysics(),
        scrollDirection: Axis.horizontal,
        children: [
          const SizedBox(width: 13),
          for(int i = 0; i < tags.length; i++)
            _buildChip(tags[i], i),
          const SizedBox(width: 13),
        ],
      ),
    );
  }

  Widget _buildChip(Tag tag, int index) {
    bool selected = index == selectedTagIndex;
    String isoCode;
    if(countryCodes.containsKey(tag.displayName))
      isoCode = countryCodes[tag.displayName];
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
        child: ChoiceChip(
          padding: EdgeInsets.symmetric(horizontal: 5),
          avatar: isoCode != null && !isMobile ? Padding(
            padding: EdgeInsets.only(left: 5),
            child: Flag(isoCode, height: 10),
          ) : null,
          elevation: 3,
          label: Padding(
            padding: EdgeInsets.only(bottom: 0),
            child: Text('${!isMobile || isoCode == null ? tag.displayName : iso2EmojiFlag(isoCode) + '  ' + tag.displayName}', style: TextStyle(
              color: selected ? Colors.white : Colors.black, 
              fontWeight: FontWeight.w500
              ),
            )
          ),
          selected: selected,
          onSelected: (bool selected) {
            setState(() {
              if(selected) {
                selectedTagIndex = index;
                widget.updateCurrentReviews('', tag: tag);
                widget.textController.text = tag.displayName;
              }
              // else {
              //   _selectedTagIndex = -1;
              //   widget.textController.text = '';
              // }
            });
          },
          backgroundColor: Colors.white,
          selectedColor: Constants.myPurple,
      ),
    );
  }
}