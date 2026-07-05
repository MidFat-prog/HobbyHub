class HobbyCategory {
  final String name;
  final String emoji;
  final String description;
  final String color;
  final List<String> learningVideos;
  final List<HobbyResource> resources;
  final String imageUrl;

  HobbyCategory({
    required this.name,
    required this.emoji,
    required this.description,
    required this.color,
    required this.learningVideos,
    required this.resources,
    required this.imageUrl,
  });
}

class HobbyResource {
  final String title;
  final String url;
  final String type; // 'website', 'article', 'shop', 'course'

  HobbyResource({
    required this.title,
    required this.url,
    required this.type,
  });
}

// 20+ Predefined hobbies with learning resources
final List<HobbyCategory> allHobbies = [
  // CREATIVE ARTS
  HobbyCategory(
    name: 'Painting',
    emoji: '🎨',
    description: 'Express yourself through colors and canvas',
    color: '0xFFFFB3BA',
    imageUrl: 'https://images.unsplash.com/photo-1460661419201-fd4cecdf8a8b?w=400',
    learningVideos: [
      'https://www.youtube.com/watch?v=o7KzL_YLYPw', // Painting for beginners
      'https://www.youtube.com/watch?v=9xQp2sldyts', // Acrylic painting basics
      'https://www.youtube.com/watch?v=fSdVs8yLjYM', // Color mixing
      'https://www.youtube.com/watch?v=9xQp2sldyts', // Acrylic painting basics
      'https://www.youtube.com/watch?v=fSdVs8yLjYM', // Color mixing
    ],
    resources: [
      HobbyResource(title: 'Artists Network - Free Tutorials', url: 'https://www.artistsnetwork.com/', type: 'website'),
      HobbyResource(title: 'Basic Painting Supplies Guide', url: 'https://www.art-is-fun.com/painting-supplies', type: 'article'),
      HobbyResource(title: 'Online Painting Course (Free)', url: 'https://www.udemy.com/topic/painting/', type: 'course'),
    ],
  ),

  HobbyCategory(
    name: 'Photography',
    emoji: '📸',
    description: 'Capture moments and tell stories through images',
    color: '0xFFE6B3FF',
    imageUrl: 'https://images.unsplash.com/photo-1452587925148-ce544e77e70d?w=400',
    learningVideos: [
      'https://www.youtube.com/watch?v=LxO-6rlihSg', // Photography basics
      'https://www.youtube.com/watch?v=V7z7BAZdt2M', // Camera settings
      'https://www.youtube.com/watch?v=x9n8VZOqaQ4', // Composition
    ],
    resources: [
      HobbyResource(title: 'Digital Photography School', url: 'https://digital-photography-school.com/', type: 'website'),
      HobbyResource(title: 'PetaPixel Photography News', url: 'https://petapixel.com/', type: 'website'),
      HobbyResource(title: 'Beginner Camera Guide', url: 'https://www.dpreview.com/buying-guides', type: 'article'),
    ],
  ),

  // CRAFTS
  HobbyCategory(
    name: 'Knitting',
    emoji: '🧶',
    description: 'Create cozy garments and accessories',
    color: '0xFFFFB3E6',
    imageUrl: 'https://images.unsplash.com/photo-1550086449-273988c3e0c3?w=400',
    learningVideos: [
      'https://www.youtube.com/watch?v=p_R1UDsNOMk', // Knitting for beginners
      'https://www.youtube.com/watch?v=ELB4PJBm18E', // Basic stitches
      'https://www.youtube.com/watch?v=AcvCs3z0W2A', // First scarf
    ],
    resources: [
      HobbyResource(title: 'Ravelry - Knitting Community', url: 'https://www.ravelry.com/', type: 'website'),
      HobbyResource(title: 'Free Knitting Patterns', url: 'https://www.allfreeknitting.com/', type: 'website'),
      HobbyResource(title: 'Beginner Knitting Supplies', url: 'https://www.thesprucecrafts.com/knitting-supplies-for-beginners-2116354', type: 'article'),
    ],
  ),

  HobbyCategory(
    name: 'Crochet',
    emoji: '🪡',
    description: 'Hook beautiful patterns and creations',
    color: '0xFFB3E5FC',
    imageUrl: 'https://images.unsplash.com/photo-1591020799732-db32a6c0c8e6?w=400',
    learningVideos: [
      'https://www.youtube.com/watch?v=aAxGTnVNJiE', // Crochet basics
      'https://www.youtube.com/watch?v=CRlLIs0Z7WU', // First project
      'https://www.youtube.com/watch?v=7IKxmr3IwSM', // Basic stitches
    ],
    resources: [
      HobbyResource(title: 'Crochet Patterns Central', url: 'https://www.crochetpatterncentral.com/', type: 'website'),
      HobbyResource(title: 'AllFreeCrochet', url: 'https://www.allfreecrochet.com/', type: 'website'),
      HobbyResource(title: 'Crochet Hook Size Guide', url: 'https://www.thesprucecrafts.com/crochet-hook-sizes-979086', type: 'article'),
    ],
  ),

  // CULINARY
  HobbyCategory(
    name: 'Baking',
    emoji: '🍰',
    description: 'Create delicious cakes, bread, and pastries',
    color: '0xFFFFF4C2',
    imageUrl: 'https://images.unsplash.com/photo-1486427944299-d1955d23e34d?w=400',
    learningVideos: [
      'https://www.youtube.com/watch?v=aTpDpM9Jmns', // Baking basics
      'https://www.youtube.com/watch?v=9Pqvvj1P3sQ', // How to bake bread
      'https://www.youtube.com/watch?v=rUlHNy9Xdmg', // Cake decorating
    ],
    resources: [
      HobbyResource(title: 'King Arthur Baking', url: 'https://www.kingarthurbaking.com/', type: 'website'),
      HobbyResource(title: "Sally's Baking Addiction", url: 'https://sallysbakingaddiction.com/', type: 'website'),
      HobbyResource(title: 'Essential Baking Tools', url: 'https://www.bonappetit.com/story/essential-baking-tools', type: 'article'),
    ],
  ),

  HobbyCategory(
    name: 'Cooking',
    emoji: '🍳',
    description: 'Master the art of delicious meals',
    color: '0xFFFFD9B3',
    imageUrl: 'https://images.unsplash.com/photo-1556910103-1c02745aae4d?w=400',
    learningVideos: [
      'https://www.youtube.com/watch?v=ZJy1ajvMU1k', // Cooking basics
      'https://www.youtube.com/watch?v=CdqVN8TKwcc', // Knife skills
      'https://www.youtube.com/watch?v=bRvn_pWa5Dk', // Cooking techniques
    ],
    resources: [
      HobbyResource(title: 'AllRecipes', url: 'https://www.allrecipes.com/', type: 'website'),
      HobbyResource(title: 'Serious Eats', url: 'https://www.seriouseats.com/', type: 'website'),
      HobbyResource(title: 'Cooking Techniques Guide', url: 'https://www.thespruceeats.com/basic-cooking-techniques-4162911', type: 'article'),
    ],
  ),

  // TECH & GAMING
  HobbyCategory(
    name: 'Video Gaming',
    emoji: '🎮',
    description: 'Explore virtual worlds and challenges',
    color: '0xFFBAB3FF',
    imageUrl: 'https://images.unsplash.com/photo-1550745165-9bc0b252726f?w=400',
    learningVideos: [
      'https://www.youtube.com/watch?v=H3aVdgeBlY0', // Gaming tips
      'https://www.youtube.com/watch?v=9dXhLLPEIJ0', // Game strategies
      'https://www.youtube.com/watch?v=0jGY-4QIL5I', // Gaming setup
    ],
    resources: [
      HobbyResource(title: 'IGN Gaming News', url: 'https://www.ign.com/', type: 'website'),
      HobbyResource(title: 'GameSpot Reviews', url: 'https://www.gamespot.com/', type: 'website'),
      HobbyResource(title: 'Best Games for Beginners', url: 'https://www.pcgamer.com/best-games-for-beginners/', type: 'article'),
    ],
  ),

  HobbyCategory(
    name: 'Programming',
    emoji: '💻',
    description: 'Build apps, websites, and solve problems with code',
    color: '0xFFB3FFB3',
    imageUrl: 'https://images.unsplash.com/photo-1461749280684-dccba630e2f6?w=400',
    learningVideos: [
      'https://www.youtube.com/watch?v=zOjov-2OZ0E', // Programming basics
      'https://www.youtube.com/watch?v=rfscVS0vtbw', // Python tutorial
      'https://www.youtube.com/watch?v=W6NZfCO5SIk', // JavaScript
    ],
    resources: [
      HobbyResource(title: 'freeCodeCamp', url: 'https://www.freecodecamp.org/', type: 'course'),
      HobbyResource(title: 'W3Schools Tutorials', url: 'https://www.w3schools.com/', type: 'website'),
      HobbyResource(title: 'Codecademy', url: 'https://www.codecademy.com/', type: 'course'),
    ],
  ),

  // ACTIVE & SPORTS
  HobbyCategory(
    name: 'Badminton',
    emoji: '🏸',
    description: 'Fast-paced racket sport for fitness and fun',
    color: '0xFFFFE6B3',
    imageUrl: 'https://images.unsplash.com/photo-1626224583764-f87db24ac4ea?w=400',
    learningVideos: [
      'https://www.youtube.com/watch?v=hxHnYy2nlcY', // Badminton basics
      'https://www.youtube.com/watch?v=dDjCrP0eSfU', // Techniques
      'https://www.youtube.com/watch?v=vMCmR15MsIQ', // Footwork
    ],
    resources: [
      HobbyResource(title: 'Badminton World Federation', url: 'https://bwfbadminton.com/', type: 'website'),
      HobbyResource(title: 'Beginner Equipment Guide', url: 'https://www.badmintonbay.com/beginners-guide/', type: 'article'),
      HobbyResource(title: 'Rules and Scoring', url: 'https://www.bwfbadminton.com/rules/', type: 'article'),
    ],
  ),

  HobbyCategory(
    name: 'Yoga',
    emoji: '🧘',
    description: 'Mind-body practice for flexibility and peace',
    color: '0xFFB3FFE6',
    imageUrl: 'https://images.unsplash.com/photo-1544367567-0f2fcb009e0b?w=400',
    learningVideos: [
      'https://www.youtube.com/watch?v=v7AYKMP6rOE', // Yoga for beginners
      'https://www.youtube.com/watch?v=oBu-pQG6sTY', // Morning yoga
      'https://www.youtube.com/watch?v=Eml2xnoLpYE', // Basic poses
    ],
    resources: [
      HobbyResource(title: 'Yoga Journal', url: 'https://www.yogajournal.com/', type: 'website'),
      HobbyResource(title: 'Poses for Beginners', url: 'https://www.verywellfit.com/yoga-poses-for-beginners-3566747', type: 'article'),
      HobbyResource(title: 'Yoga Equipment Guide', url: 'https://www.yogabasics.com/learn/yoga-equipment/', type: 'article'),
    ],
  ),

  // MIND & LEARNING
  HobbyCategory(
    name: 'Reading',
    emoji: '📚',
    description: 'Explore worlds and gain knowledge through books',
    color: '0xFFD4B3FF',
    imageUrl: 'https://images.unsplash.com/photo-1481627834876-b7833e8f5570?w=400',
    learningVideos: [
      'https://www.youtube.com/watch?v=lIW5jBrrsS0', // How to read more
      'https://www.youtube.com/watch?v=lNkgn8o8M5c', // Speed reading
      'https://www.youtube.com/watch?v=7bXJ_obaiYQ', // Book recommendations
    ],
    resources: [
      HobbyResource(title: 'Goodreads', url: 'https://www.goodreads.com/', type: 'website'),
      HobbyResource(title: 'Project Gutenberg (Free Books)', url: 'https://www.gutenberg.org/', type: 'website'),
      HobbyResource(title: 'Book Recommendations', url: 'https://www.nytimes.com/books/best-sellers/', type: 'article'),
    ],
  ),

  HobbyCategory(
    name: 'Gardening',
    emoji: '🌱',
    description: 'Grow plants and connect with nature',
    color: '0xFFB3FFB3',
    imageUrl: 'https://images.unsplash.com/photo-1416879595882-3373a0480b5b?w=400',
    learningVideos: [
      'https://www.youtube.com/watch?v=lM0NVy3RqMo', // Gardening for beginners
      'https://www.youtube.com/watch?v=kJdwfI4OVEM', // How to start
      'https://www.youtube.com/watch?v=B0ZdKK7sXTY', // Container gardening
    ],
    resources: [
      HobbyResource(title: 'The Old Farmer\'s Almanac', url: 'https://www.almanac.com/gardening', type: 'website'),
      HobbyResource(title: 'Gardening Know How', url: 'https://www.gardeningknowhow.com/', type: 'website'),
      HobbyResource(title: 'Beginner Gardening Guide', url: 'https://www.bhg.com/gardening/yard/garden-care/starting-a-garden/', type: 'article'),
    ],
  ),

  // Additional hobbies...
  HobbyCategory(
    name: 'Drawing',
    emoji: '✏️',
    description: 'Sketch your imagination on paper',
    color: '0xFFFFB3D4',
    imageUrl: 'https://images.unsplash.com/photo-1513364776144-60967b0f800f?w=400',
    learningVideos: [
      'https://www.youtube.com/watch?v=ewMksAbgdBI', // Drawing basics
      'https://www.youtube.com/watch?v=_28lc-4DOXA', // Shading techniques
    ],
    resources: [
      HobbyResource(title: 'Drawspace', url: 'https://www.drawspace.com/', type: 'website'),
      HobbyResource(title: 'Drawing Supplies Guide', url: 'https://www.arteza.com/blog/drawing-supplies-list', type: 'article'),
    ],
  ),

  HobbyCategory(
    name: 'Music',
    emoji: '🎵',
    description: 'Learn instruments and create melodies',
    color: '0xFFB3D4FF',
    imageUrl: 'https://images.unsplash.com/photo-1511379938547-c1f69419868d?w=400',
    learningVideos: [
      'https://www.youtube.com/watch?v=rDl8PyLE2jE', // Music theory
      'https://www.youtube.com/watch?v=rgaTLrZGlk0', // Guitar basics
    ],
    resources: [
      HobbyResource(title: 'MusicTheory.net', url: 'https://www.musictheory.net/', type: 'website'),
      HobbyResource(title: 'JustinGuitar (Free Lessons)', url: 'https://www.justinguitar.com/', type: 'course'),
    ],
  ),

  HobbyCategory(
    name: 'Writing',
    emoji: '✍️',
    description: 'Craft stories, poems, and express thoughts',
    color: '0xFFFFE6B3',
    imageUrl: 'https://images.unsplash.com/photo-1455390582262-044cdead277a?w=400',
    learningVideos: [
      'https://www.youtube.com/watch?v=xGJ8UmmJL3E', // Creative writing
      'https://www.youtube.com/watch?v=fXe-Qsrvx-A', // Writing tips
    ],
    resources: [
      HobbyResource(title: 'Writer\'s Digest', url: 'https://www.writersdigest.com/', type: 'website'),
      HobbyResource(title: 'Writing Prompts', url: 'https://blog.reedsy.com/creative-writing-prompts/', type: 'article'),
    ],
  ),
];