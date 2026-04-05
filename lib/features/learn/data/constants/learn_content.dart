import 'package:bloomsafe/core/constants/strings.dart';

// Article categories
const List<String> articleCategories = [
  airQualityBasicsTitle,
  fertilityImpactTitle,
  pregnancyConsiderationsTitle,
];

// Article structure
const Map<String, List<Map<String, dynamic>>> learningArticles = {
  'airQualityBasics': [
    {
      'title':
          'Fine particulate matter and ovarian health: A review of emerging risks',
      'readTime': 8,
      'keyTakeaways': [
        'PM2.5 exposure is linked to decreased ovarian reserve markers including lower AMH levels and reduced follicle counts',
        'Women experiencing higher exposure to PM2.5 show hormonal changes that may affect fertility',
        'The effect appears stronger in women over 35, making air quality monitoring especially important for this demographic',
      ],
      'externalUrl': 'https://pmc.ncbi.nlm.nih.gov/articles/PMC11625118/',
      'description':
          'An examination of the relationship between fine particulate matter exposure and women\'s ovarian health, focusing on markers of ovarian reserve and fertility potential.',
    },
    {
      'title':
          'Long term exposure to road traffic noise and air pollution and risk of infertility',
      'readTime': 6,
      'keyTakeaways': [
        'Nationwide Danish study of over 900,000 people found PM2.5 exposure significantly increased infertility risk',
        'Men showed a 24% higher risk of infertility diagnosis with increased PM2.5 exposure',
        'Women living near major roadways showed altered fertility patterns',
      ],
      'externalUrl': 'https://www.bmj.com/content/386/bmj-2024-080664',
      'description':
          'Comprehensive study examining the connections between environmental pollution from traffic sources and infertility risk in both men and women.',
    },
    {
      'title': 'Exposure to air pollution and ovarian reserve parameters',
      'readTime': 10,
      'keyTakeaways': [
        'Research shows negative associations between PM2.5 exposure and both AMH levels and antral follicle count',
        'Effects of air pollution on fertility markers were most pronounced in women with pre-existing fertility challenges',
        'Multiple pollutants were studied, with PM2.5 showing the strongest correlation to decreased ovarian reserve',
      ],
      'externalUrl': 'https://www.nature.com/articles/s41598-023-50753-6',
      'description':
          'Scientific investigation into the specific effects of air pollution exposure on measurable markers of female reproductive potential.',
    },
  ],
  'fertilityImpact': [
    {
      'title':
          'Fine particulate air pollution may play a role in adverse birth outcomes',
      'readTime': 5,
      'keyTakeaways': [
        'Harvard research shows PM2.5 exposure alters immune responses during pregnancy',
        'These changes are linked to pregnancy complications including preeclampsia and low birth weight',
        'The effects were observable at the cellular level, highlighting the importance of clean air during pregnancy',
      ],
      'externalUrl':
          'https://hsph.harvard.edu/news/fine-particulate-air-pollution-may-play-a-role-in-adverse-birth-outcomes/',
      'description':
          'Harvard research examining how fine particulate matter affects immune function during pregnancy and its potential role in pregnancy complications.',
    },
    {
      'title':
          'Factsheet on air pollution, climate change and reproductive health',
      'readTime': 12,
      'keyTakeaways': [
        'Living more than 200 meters from major roads increases pregnancy rates by approximately 3%',
        'High PM2.5 exposure significantly decreases live birth rates in affected areas',
        'Women undergoing fertility treatments show particular sensitivity to air pollution exposure',
      ],
      'externalUrl':
          'https://www.eshre.eu/-/media/sitecore-files/Factsheets/FACT-SHEET-Climate-change-2024_03_04.pdf',
      'description':
          'Comprehensive factsheet from the European Society of Human Reproduction and Embryology on the intersections between environmental factors and reproductive outcomes.',
    },
    {
      'title':
          'Very Early Pregnancy Loss: The Role of PM2.5 Exposure in IVF-ET Patients',
      'readTime': 7,
      'keyTakeaways': [
        'Study identifies specific time windows when PM2.5 exposure is most detrimental to early pregnancy',
        'Women undergoing fresh embryo transfers showed particular vulnerability to air pollution effects',
        'Research reinforces the biological connection between air quality and pregnancy establishment',
      ],
      'externalUrl': 'https://pmc.ncbi.nlm.nih.gov/articles/PMC11808209/',
      'description':
          'Research focusing on the critical early stages of pregnancy and how air quality may influence pregnancy establishment and maintenance in assisted reproduction patients.',
    },
  ],
  'pregnancyConsiderations': [
    {
      'title':
          'Air pollution and its effects on female fertility: a comprehensive review',
      'readTime': 9,
      'keyTakeaways': [
        'Practical strategies for reducing exposure to air pollutants when trying to conceive',
        'How maintaining a healthy lifestyle can help mitigate some effects of air pollution on fertility',
        'The importance of discussing environmental exposures with healthcare providers',
      ],
      'externalUrl':
          'https://www.inovifertility.com/blog/air-pollution-and-its-effects-on-female-fertility/',
      'description':
          'Comprehensive review of air pollution\'s effects on fertility with practical guidance for women trying to conceive in areas with air quality concerns.',
    },
    {
      'title':
          'Does Air Pollution Play a Role in Infertility?: a Systematic Review',
      'readTime': 11,
      'keyTakeaways': [
        'Evidence-based review of air pollutants\' effects on fertility and reproductive outcomes',
        'Identification of most harmful pollutants and their mechanisms of action on reproductive systems',
        'Recommendations for protection based on scientific consensus',
      ],
      'externalUrl': 'https://pmc.ncbi.nlm.nih.gov/articles/PMC5534122/',
      'description':
          'Systematic scientific review examining the evidence linking various air pollutants to fertility challenges and proposing protective measures.',
    },
    {
      'title': 'Air pollution linked to poor fertility treatment outcomes',
      'readTime': 4,
      'keyTakeaways': [
        'Large-scale study shows higher concentrations of pollutants reduced conception rates following fertility treatment',
        'Different pollutants affect different stages of the conception process',
        'Practical considerations for women undergoing fertility treatments in areas with air quality concerns',
      ],
      'externalUrl':
          'https://www.progress.org.uk/air-pollution-linked-to-poor-fertility-treatment-outcomes/',
      'description':
          'Analysis of how air pollution specifically impacts the success rates of fertility treatments and what patients can do to optimize their chances.',
    },
  ],
};
