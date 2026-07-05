class Hobby {
  final String name;
  final String image;
  final String color;

  Hobby({
    required this.name,
    required this.image,
    required this.color,
  });
}

// Predefined hobbies
final List<Hobby> availableHobbies = [
  Hobby(name: 'Baking', image: 'baking', color: '0xFFFFF4C2'),
  Hobby(name: 'Cooking', image: 'cooking', color: '0xFFFFB3BA'),
  Hobby(name: 'Video Games', image: 'videogames', color: '0xFFBAB3FF'),
  Hobby(name: 'Crochet', image: 'crochet', color: '0xFFB3E5FC'),
  Hobby(name: 'Knitting', image: 'knitting', color: '0xFFFFB3E6'),
  Hobby(name: 'Reading', image: 'reading', color: '0xFFB3FFB3'),
  Hobby(name: 'Badminton', image: 'badminton', color: '0xFFFFD9B3'),
  Hobby(name: 'Photography', image: 'photography', color: '0xFFE6B3FF'),
  Hobby(name: 'Painting', image: 'painting', color: '0xFFFFE6B3'),
  Hobby(name: 'Gardening', image: 'gardening', color: '0xFFB3FFE6'),
  Hobby(name: 'Music', image: 'music', color: '0xFFD4B3FF'),
  Hobby(name: 'Fitness', image: 'fitness', color: '0xFFFFB3D4'),
];
