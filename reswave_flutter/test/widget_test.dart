import 'package:flutter_test/flutter_test.dart';
import 'package:reswave/core/utils/matching_calculator.dart';
import 'package:reswave/core/utils/validators.dart';
import 'package:reswave/models/user_model.dart';
import 'package:reswave/models/research_interest.dart';

void main() {
  group('ResWave Unit & Logic Tests', () {
    test('Validators correctly validate required fields and formats', () {
      expect(Validators.validateName(''), isNotNull);
      expect(Validators.validateName('A'), isNotNull);
      expect(Validators.validateName('Alex Rivera'), isNull);

      expect(Validators.validateEmail('invalid-email'), isNotNull);
      expect(Validators.validateEmail('alex@cmu.edu'), isNull);

      expect(Validators.validatePassword('short'), isNotNull);
      expect(Validators.validatePassword('validPassword123'), isNull);
    });

    test('MatchingCalculator computes 5-factor domain scores accurately', () {
      final domain = {
        'subjectTags': ['computing', 'design'],
        'problemTags': ['human behaviour', 'technology'],
        'workStyleTags': ['building prototypes'],
        'skillTags': ['programming', 'design'],
        'goalTags': ['explore'],
        'keywords': ['interfaces', 'accessibility'],
      };

      final answers = {
        'subjects': ['computing', 'design'],
        'problems': ['human behaviour', 'technology'],
        'workStyles': ['building prototypes'],
        'skills': ['programming', 'design'],
        'goals': ['explore'],
      };

      final result = MatchingCalculator.scoreDomain(
        userAnswers: answers,
        domainTaxonomy: domain,
      );

      expect(result['score'], greaterThan(80.0));
      expect(result['fitBand'], equals('Strong'));
      expect((result['reasons'] as List).length, greaterThan(0));
    });

    test('MatchingCalculator redistributes weights proportionally when questions skipped', () {
      final domain = {
        'subjectTags': ['computing'],
        'problemTags': ['technology'],
        'workStyleTags': ['experiments'],
        'skillTags': ['programming'],
        'goalTags': ['explore'],
      };

      final answersWithSkips = {
        'subjects': ['computing'],
        'problems': ['technology'],
        'workStyles': ['skip'],
        'skills': ['not sure'],
        'goals': ['explore'],
      };

      final result = MatchingCalculator.scoreDomain(
        userAnswers: answersWithSkips,
        domainTaxonomy: domain,
      );

      expect(result['score'], greaterThan(0.0));
      expect(result['fitBand'], isIn(['Strong', 'Possible', 'Explore']));
    });

    test('ResearchInterest supports multi-domain independence', () {
      final int1 = ResearchInterest(
        id: 'int-1',
        userId: 'usr-1',
        domainId: 'hci',
        subdomainId: 'Cognitive Ergonomics',
        topicTags: ['cognitive load'],
        goals: ['Publish'],
      );

      final int2 = ResearchInterest(
        id: 'int-2',
        userId: 'usr-1',
        domainId: 'ai-nlp',
        subdomainId: 'NLP',
        topicTags: ['transformers'],
        goals: ['Learn'],
      );

      expect(int1.domainId, equals('hci'));
      expect(int2.domainId, equals('ai-nlp'));
      expect(int1.subdomainId, isNot(equals(int2.subdomainId)));
    });

    test('UserModel serialization and role properties', () {
      final user = UserModel(
        uid: 'usr-test-1',
        email: 'scholar@uni.edu',
        displayName: 'Dr. Test',
        role: 'PhD Scholar',
        country: 'Germany',
        institution: 'TU Munich',
        discoverable: true,
      );

      final json = user.toJson();
      expect(json['uid'], equals('usr-test-1'));
      expect(json['role'], equals('PhD Scholar'));
      expect(json['discoverable'], isTrue);

      final restored = UserModel.fromJson(json);
      expect(restored.displayName, equals('Dr. Test'));
      expect(restored.institution, equals('TU Munich'));
    });
  });
}
