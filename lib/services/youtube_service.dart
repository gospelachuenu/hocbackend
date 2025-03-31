import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/app_config.dart';

class YoutubeService {
  String get _apiKey => AppConfig.youtubeApiKey;
  String get _channelId => AppConfig.youtubeChannelId;

  Future<String?> getCurrentLiveStreamId() async {
    try {
      print('Fetching live stream from YouTube API...');
      print('Using Channel ID: $_channelId');
      print('Using API Key: $_apiKey');
      
      final url = 'https://www.googleapis.com/youtube/v3/search?part=snippet&channelId=$_channelId&eventType=live&type=video&key=$_apiKey';
      print('API URL: $url');
      
      final response = await http.get(Uri.parse(url));

      print('API Response Status: ${response.statusCode}');
      print('API Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['items'] != null && data['items'].isNotEmpty) {
          final videoId = data['items'][0]['id']['videoId'];
          print('Found live stream ID: $videoId');
          print('Stream title: ${data['items'][0]['snippet']['title']}');
          print('Stream description: ${data['items'][0]['snippet']['description']}');
          return videoId;
        } else {
          print('No live streams found in API response');
          return null;
        }
      } else {
        print('API request failed with status: ${response.statusCode}');
        print('Error response: ${response.body}');
        return null;
      }
    } catch (e) {
      print('Error fetching live stream: $e');
      return null;
    }
  }

  Future<Map<String, dynamic>?> getCurrentLiveStreamInfo() async {
    try {
      print('Checking for live stream...');
      print('Using Channel ID: $_channelId');
      print('Using API Key: $_apiKey');
      
      if (_apiKey.isEmpty || _channelId.isEmpty) {
        print('Error: YouTube API key or Channel ID is not configured');
        return null;
      }

      // First, let's verify the API key works with a simple search
      final testUrl = 'https://www.googleapis.com/youtube/v3/search?part=snippet&q=test&type=video&key=$_apiKey';
      print('Testing API key with URL: $testUrl');
      
      final testResponse = await http.get(Uri.parse(testUrl));
      print('Test API response status: ${testResponse.statusCode}');
      print('Test API response headers: ${testResponse.headers}');
      print('Test API response body: ${testResponse.body}');

      if (testResponse.statusCode != 200) {
        print('API key test failed. Status: ${testResponse.statusCode}');
        print('Error details: ${testResponse.body}');
        return null;
      }

      // Now try the live stream search
      final searchUrl = 'https://www.googleapis.com/youtube/v3/search?part=snippet&channelId=$_channelId&eventType=live&type=video&key=$_apiKey';
      print('Search API URL: $searchUrl');
      
      final response = await http.get(Uri.parse(searchUrl));
      print('Search API response status: ${response.statusCode}');
      print('Search API response headers: ${response.headers}');
      print('Search API response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final items = data['items'] as List;
        
        if (items.isEmpty) {
          print('No live streams found');
          return null;
        }

        final videoId = items[0]['id']['videoId'];
        final snippet = items[0]['snippet'];
        
        print('Found potential live stream: ${snippet['title']}');
        
        // Check if the stream is actually live by getting video details
        final videoUrl = 'https://www.googleapis.com/youtube/v3/videos?part=contentDetails,liveStreamingDetails&id=$videoId&key=$_apiKey';
        print('Video details API URL: $videoUrl');
        
        final videoResponse = await http.get(Uri.parse(videoUrl));
        print('Video details API response status: ${videoResponse.statusCode}');
        print('Video details API response body: ${videoResponse.body}');

        if (videoResponse.statusCode == 200) {
          final videoData = json.decode(videoResponse.body);
          final videoItems = videoData['items'] as List;
          
          if (videoItems.isEmpty) {
            print('Video details not found');
            return null;
          }

          final contentDetails = videoItems[0]['contentDetails'];
          final liveStreamingDetails = videoItems[0]['liveStreamingDetails'];
          
          // Check if the video is actually live
          if (liveStreamingDetails == null || 
              liveStreamingDetails['actualEndTime'] != null ||
              liveStreamingDetails['activeLiveChatId'] == null) {
            print('Stream is not live or has ended');
            return null;
          }

          print('Confirmed live stream: ${snippet['title']}');
          return {
            'videoId': videoId,
            'title': snippet['title'],
            'description': snippet['description'],
          };
        } else {
          print('Error getting video details: ${videoResponse.statusCode}');
          print('Error response: ${videoResponse.body}');
          return null;
        }
      } else if (response.statusCode == 403) {
        print('API key error: The provided API key is invalid or has been revoked');
        print('Please check your YouTube API key configuration');
        return null;
      } else {
        print('Error searching for live stream: ${response.statusCode}');
        print('Error response: ${response.body}');
        return null;
      }
    } catch (e) {
      print('Error getting live stream info: $e');
      return null;
    }
  }
} 