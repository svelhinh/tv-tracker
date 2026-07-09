import 'package:flutter_test/flutter_test.dart';
import 'package:tv_tracker/core/metrics/tmdb_api_metrics.dart';
import 'package:tv_tracker/features/matching/data/tmdb_client.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  group('TmdbClient metrics', () {
    test('records successful API calls', () async {
      final metrics = TmdbApiMetrics();
      final client = TmdbClient(
        apiKey: 'test-key',
        httpClient: MockClient((request) async {
          return http.Response(
            '{"results":[{"id":1,"name":"Test","popularity":1}]}',
            200,
          );
        }),
        metrics: metrics,
      );

      await client.searchTv('Test');
      client.close();

      expect(metrics.callCount, 1);
      expect(metrics.errorCount, 0);
      expect(metrics.totalLatency, isNot(Duration.zero));
    });

    test('records cache hits without extra API calls', () async {
      var requestCount = 0;
      final metrics = TmdbApiMetrics();
      final client = TmdbClient(
        apiKey: 'test-key',
        httpClient: MockClient((request) async {
          requestCount++;
          return http.Response(
            '{"results":[{"id":1,"name":"Test","popularity":1}]}',
            200,
          );
        }),
        metrics: metrics,
      );

      await client.searchTv('Test');
      await client.searchTv('Test');
      await client.searchTv('test');
      client.close();

      expect(requestCount, 1);
      expect(metrics.callCount, 1);
      expect(metrics.cacheHitCount, 2);
    });

    test('records failed API calls', () async {
      final metrics = TmdbApiMetrics();
      final client = TmdbClient(
        apiKey: 'test-key',
        httpClient: MockClient((request) async {
          return http.Response('error', 500);
        }),
        metrics: metrics,
      );

      await expectLater(client.searchTv('Test'), throwsA(isA<TmdbException>()));
      client.close();

      expect(metrics.callCount, 1);
      expect(metrics.errorCount, 1);
    });
  });
}
