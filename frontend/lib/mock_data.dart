import 'models/destination.dart';
import 'models/user.dart';
import 'models/vote.dart';

const mockActiveUser = TravelPickUser(
  id: 1,
  name: 'You',
  groupName: 'Weekend Wanderers',
  groupCode: 'TP-482',
);

const mockExpectedVoters = 8;
const mockSubmittedVoters = 6;

const mockDestinations = [
  Destination(
    id: 1,
    name: 'Banff',
    country: 'Canada',
    imageUrl:
        'https://images.unsplash.com/photo-1501785888041-af3ef285b470?auto=format&fit=crop&w=900&q=80',
    rating: 4.8,
    popularity: 92,
    description:
        'Alpine lakes, glacier-fed trails, and easy scenic drives make Banff a strong pick for an outdoorsy group escape.',
    estimatedCost: r'$1,450 / person',
    bestSeason: 'June to September',
  ),
  Destination(
    id: 2,
    name: 'Kyoto',
    country: 'Japan',
    imageUrl:
        'https://images.unsplash.com/photo-1493976040374-85c8e12f0c0e?auto=format&fit=crop&w=900&q=80',
    rating: 4.9,
    popularity: 96,
    description:
        'A graceful mix of temples, night markets, gardens, and walkable neighborhoods for travelers who want culture without rushing.',
    estimatedCost: r'$1,820 / person',
    bestSeason: 'March to May',
  ),
  Destination(
    id: 3,
    name: 'Santorini',
    country: 'Greece',
    imageUrl:
        'https://images.unsplash.com/photo-1570077188670-e3a8d69ac5ff?auto=format&fit=crop&w=900&q=80',
    rating: 4.7,
    popularity: 89,
    description:
        'Sunlit cliff towns, blue water views, and slow dinners make Santorini ideal for a relaxed celebration trip.',
    estimatedCost: r'$1,960 / person',
    bestSeason: 'April to October',
  ),
  Destination(
    id: 4,
    name: 'Bali',
    country: 'Indonesia',
    imageUrl:
        'https://images.unsplash.com/photo-1537996194471-e657df975ab4?auto=format&fit=crop&w=900&q=80',
    rating: 4.6,
    popularity: 94,
    description:
        'Beach clubs, rice terraces, wellness stays, and day trips give mixed-interest groups plenty of ways to split and regroup.',
    estimatedCost: r'$1,280 / person',
    bestSeason: 'May to September',
  ),
  Destination(
    id: 5,
    name: 'Cape Town',
    country: 'South Africa',
    imageUrl:
        'https://images.unsplash.com/photo-1580060839134-75a5edca2e99?auto=format&fit=crop&w=900&q=80',
    rating: 4.7,
    popularity: 87,
    description:
        'Coastal drives, vineyards, hikes, and city energy create a varied itinerary with strong value for adventurous groups.',
    estimatedCost: r'$1,520 / person',
    bestSeason: 'November to March',
  ),
  Destination(
    id: 6,
    name: 'Queenstown',
    country: 'New Zealand',
    imageUrl:
        'https://images.unsplash.com/photo-1500530855697-b586d89ba3ee?auto=format&fit=crop&w=900&q=80',
    rating: 4.8,
    popularity: 91,
    description:
        'A compact adventure base with lake views, mountain day trips, and enough food and wine to balance the adrenaline.',
    estimatedCost: r'$2,120 / person',
    bestSeason: 'December to February',
  ),
];

const mockGroupVotes = [
  Vote(userId: 2, destinationId: 1, weight: 3),
  Vote(userId: 2, destinationId: 2, weight: 2),
  Vote(userId: 2, destinationId: 3, weight: 1),
  Vote(userId: 2, destinationId: 4, weight: 2),
  Vote(userId: 2, destinationId: 5, weight: 1),
  Vote(userId: 2, destinationId: 6, weight: 2),
  Vote(userId: 3, destinationId: 1, weight: 2),
  Vote(userId: 3, destinationId: 2, weight: 3),
  Vote(userId: 3, destinationId: 3, weight: 2),
  Vote(userId: 3, destinationId: 4, weight: 3),
  Vote(userId: 3, destinationId: 5, weight: 2),
  Vote(userId: 3, destinationId: 6, weight: 1),
  Vote(userId: 4, destinationId: 1, weight: 1),
  Vote(userId: 4, destinationId: 2, weight: 3),
  Vote(userId: 4, destinationId: 3, weight: 2),
  Vote(userId: 4, destinationId: 4, weight: 2),
  Vote(userId: 4, destinationId: 5, weight: 1),
  Vote(userId: 4, destinationId: 6, weight: 3),
  Vote(userId: 5, destinationId: 1, weight: 2),
  Vote(userId: 5, destinationId: 2, weight: 3),
  Vote(userId: 5, destinationId: 3, weight: 1),
  Vote(userId: 5, destinationId: 4, weight: 2),
  Vote(userId: 5, destinationId: 5, weight: 2),
  Vote(userId: 5, destinationId: 6, weight: 2),
  Vote(userId: 6, destinationId: 1, weight: 2),
  Vote(userId: 6, destinationId: 2, weight: 2),
  Vote(userId: 6, destinationId: 3, weight: 3),
  Vote(userId: 6, destinationId: 4, weight: 1),
  Vote(userId: 6, destinationId: 5, weight: 2),
  Vote(userId: 6, destinationId: 6, weight: 1),
  Vote(userId: 7, destinationId: 1, weight: 1),
  Vote(userId: 7, destinationId: 2, weight: 3),
  Vote(userId: 7, destinationId: 3, weight: 2),
  Vote(userId: 7, destinationId: 4, weight: 2),
  Vote(userId: 7, destinationId: 5, weight: 1),
  Vote(userId: 7, destinationId: 6, weight: 2),
];
