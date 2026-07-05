import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class LocationSelectorScreen extends StatefulWidget {
  final bool isFromProfile;

  const LocationSelectorScreen({super.key, this.isFromProfile = false});

  @override
  State<LocationSelectorScreen> createState() => _LocationSelectorScreenState();
}

class _LocationSelectorScreenState extends State<LocationSelectorScreen> {
  String? selectedCity;
  String? selectedArea;
  bool isLoading = false;

  final Map<String, List<String>> cityAreas = {
    'Lahore': [
      // Central Areas
      'Gulberg',
      'Model Town',
      'Garden Town',
      'Faisal Town',
      'Iqbal Town',
      'Johar Town',
      'Wapda Town',
      'Township',
      'Allama Iqbal Town',
      // DHA & Cantt
      'DHA Phase 1',
      'DHA Phase 2',
      'DHA Phase 3',
      'DHA Phase 4',
      'DHA Phase 5',
      'DHA Phase 6',
      'DHA Phase 7',
      'DHA Phase 8',
      'Cantt',
      'Cavalry Ground',
      // Bahria Town
      'Bahria Town',
      'Bahria Orchard',
      // Other Major Areas
      'Shadman',
      'Samanabad',
      'Mustafa Town',
      'Green Town',
      'Valencia Town',
      'Eden Gardens',
      'Lake City',
      'State Life Society',
      'PCSIR Society',
      'PIA Society',
      'Ali Town',
      'Sabzazar',
      'Shahdara',
      'Raiwind',
      'Thokar Niaz Baig',
      'Harbanspura',
      'Shalimar Town',
      'Wahdat Colony',
      'EME Society',
      'Askari',
      'Canal Road',
      'Mall Road',
      'Liberty',
      'MM Alam Road',
    ],
    'Karachi': [
      // DHA
      'DHA Phase 1',
      'DHA Phase 2',
      'DHA Phase 4',
      'DHA Phase 5',
      'DHA Phase 6',
      'DHA Phase 7',
      'DHA Phase 8',
      // Clifton & Surroundings
      'Clifton',
      'Clifton Block 2',
      'Clifton Block 4',
      'Clifton Block 5',
      'Clifton Block 8',
      'Sea View',
      'Bath Island',
      // Gulshan
      'Gulshan-e-Iqbal',
      'Gulshan-e-Iqbal Block 13',
      'Gulshan-e-Iqbal Block 14',
      'Gulshan-e-Iqbal Block 15',
      'Gulistan-e-Johar',
      // North Karachi
      'North Nazimabad',
      'North Nazimabad Block A',
      'North Nazimabad Block B',
      'North Karachi',
      'New Karachi',
      // Central Areas
      'Saddar',
      'PECHS',
      'PECHS Block 2',
      'PECHS Block 6',
      'Bahadurabad',
      'Tariq Road',
      'Shahrah-e-Faisal',
      'Shahra-e-Quaideen',
      // East Karachi
      'Malir',
      'Malir Cantt',
      'Korangi',
      'Korangi Industrial Area',
      'Landhi',
      'Model Colony',
      // West Karachi
      'Orangi Town',
      'Baldia Town',
      'SITE',
      'Surjani Town',
      // Bahria & Others
      'Bahria Town',
      'Bahria Sports City',
      'Scheme 33',
      'Federal B Area',
      'Nazimabad',
      'Liaquatabad',
      'Buffer Zone',
      'Garden East',
      'Garden West',
      'Karsaz',
      'Nursery',
    ],
    'Islamabad': [
      // F Sectors
      'F-6',
      'F-6/1',
      'F-6/2',
      'F-6/3',
      'F-7',
      'F-7/1',
      'F-7/2',
      'F-7/3',
      'F-8',
      'F-8/1',
      'F-8/2',
      'F-8/3',
      'F-8/4',
      'F-10',
      'F-10/1',
      'F-10/2',
      'F-10/3',
      'F-11',
      // G Sectors
      'G-6',
      'G-6/1',
      'G-6/2',
      'G-6/3',
      'G-6/4',
      'G-7',
      'G-7/1',
      'G-7/2',
      'G-7/3',
      'G-7/4',
      'G-8',
      'G-9',
      'G-9/1',
      'G-9/2',
      'G-9/3',
      'G-9/4',
      'G-10',
      'G-10/1',
      'G-10/2',
      'G-10/3',
      'G-10/4',
      'G-11',
      'G-13',
      'G-14',
      'G-15',
      // I Sectors
      'I-8',
      'I-8/1',
      'I-8/2',
      'I-8/3',
      'I-9',
      'I-10',
      'I-11',
      'I-14',
      // Other Areas
      'Blue Area',
      'Jinnah Avenue',
      'Constitution Avenue',
      'Diplomatic Enclave',
      'Bahria Town',
      'Bahria Enclave',
      'DHA Phase 1',
      'DHA Phase 2',
      'PWD',
      'AECHS',
      'Naval Anchorage',
      'Gulberg Greens',
      'Gulberg Residencia',
      'E-11',
      'D-12',
      'B-17',
    ],
    'Rawalpindi': [
      // Bahria Town
      'Bahria Town Phase 1',
      'Bahria Town Phase 2',
      'Bahria Town Phase 3',
      'Bahria Town Phase 4',
      'Bahria Town Phase 5',
      'Bahria Town Phase 6',
      'Bahria Town Phase 7',
      'Bahria Town Phase 8',
      // DHA
      'DHA Phase 1',
      'DHA Phase 2',
      'DHA Phase 3',
      // Central Areas
      'Saddar',
      'Saddar Bazaar',
      'Raja Bazaar',
      'Commercial Market',
      'Committee Chowk',
      'Murree Road',
      // Satellite Town
      'Satellite Town',
      'Satellite Town Block A',
      'Satellite Town Block B',
      'Satellite Town Block C',
      'Satellite Town Block D',
      'Satellite Town Block E',
      // Cantt Areas
      'Chaklala',
      'Chaklala Scheme 3',
      'Westridge',
      'Mall Road',
      // PWD & Surroundings
      'PWD',
      'PWD Colony',
      'Peoples Colony',
      'Askari',
      // Other Major Areas
      'Gulzar-e-Quaid',
      'Gulistan Colony',
      'Dhoke Syedan',
      'Dhoke Ratta',
      'Dhoke Kashmirian',
      'Committee Chowk',
      'Chandni Chowk',
      'Allama Iqbal Colony',
      'Afshan Colony',
      'Adiala Road',
      'Sixth Road',
      'Peshawar Road',
      'Airport Road',
    ],
    'Faisalabad': [
      // Major Areas
      'D Ground',
      'People Colony',
      'Susan Road',
      'Gulberg',
      'Madina Town',
      'Samanabad',
      'Jinnah Colony',
      'Millat Town',
      'Allama Iqbal Colony',
      'Kohinoor City',
      'Canal Road',
      'Sargodha Road',
      'Jaranwala Road',
      'Satiana Road',
      'Samundri Road',
      // Societies
      'Eden Valley',
      'Abdullah Garden',
      'Green Fort',
      'Citi Housing',
      'Canal Garden',
      'Dream Gardens',
      'Sitara Supreme City',
      'Fazaia Housing Scheme',
      // Other Areas
      'Ghulam Muhammad Abad',
      'Model Town',
      'Civil Lines',
      'Peoples Colony',
      'Nishatabad',
      'Ayub Agricultural Research',
      'Khurrianwala',
      'Chak Jhumra',
    ],
    'Multan': [
      'Cantt',
      'DHA',
      'Gulgasht Colony',
      'Model Town',
      'Shah Rukn-e-Alam Colony',
      'Bosan Road',
      'New Multan',
      'Old Multan',
      'Shershah Road',
      'Abdali Road',
      'MDA Chowk',
      'Chungi No. 9',
      'Vehari Chowk',
      'Suraj Miani',
      'Gardezi Town',
      'Officers Colony',
      'Mumtazabad',
      'Khanewal Road',
      'Bahawalpur Road',
      'Northern Bypass',
      'Wapda Town',
      'New Shujabad Road',
    ],
    'Peshawar': [
      'Hayatabad',
      'Hayatabad Phase 1',
      'Hayatabad Phase 2',
      'Hayatabad Phase 3',
      'Hayatabad Phase 4',
      'Hayatabad Phase 5',
      'Hayatabad Phase 6',
      'Hayatabad Phase 7',
      'University Town',
      'Cantt',
      'Saddar',
      'Board Bazaar',
      'Khyber Bazaar',
      'Qissa Khawani Bazaar',
      'Shami Road',
      'Old Bara Road',
      'Jamrud Road',
      'GT Road',
      'Ring Road',
      'Warsak Road',
      'Dalazak Road',
      'Abdara Road',
      'Tehkal',
      'Regi',
      'Nasir Bagh Road',
      'Pajagi',
    ],
    'Quetta': [
      'Cantt',
      'Civil Lines',
      'Jinnah Town',
      'Satellite Town',
      'Model Town',
      'Brewery Road',
      'Killi Kamalo',
      'Killi Ismail',
      'Pashtunabad',
      'Hazara Town',
      'Marriabad',
      'Samungli Road',
      'Sariab Road',
      'Jail Road',
      'Airport Road',
      'Zarghoon Road',
      'Shahrah-e-Iqbal',
    ],
    'Sialkot': [
      'Cantt',
      'Model Town',
      'Allama Iqbal Town',
      'Paris Road',
      'Saddar Bazaar',
      'Defence Road',
      'Circular Road',
      'Civil Lines',
      'Kot Baloch',
      'Hajipura',
      'Adalat Bazaar',
      'Nekapura',
      'Gohadpur',
      'Rangpura',
      'Nai Abadi',
    ],
    'Gujranwala': [
      'Model Town',
      'Peoples Colony',
      'Satellite Town',
      'Cantt',
      'Civil Lines',
      'G.T. Road',
      'Jinnah Road',
      'Rahwali',
      'DC Road',
      'Khiali',
      'New Satellite Town',
      'Eminabad',
      'Green Valley',
      'Gondlanwala',
    ],
    'Bahawalpur': [
      'Cantt',
      'Model Town A',
      'Model Town B',
      'Model Town C',
      'Satellite Town',
      'Baghdad-ul-Jadeed',
      'Farid Gate',
      'Multan Road',
      'Ahmad Pur Road',
      'Circular Road',
      'DCO Colony',
    ],
  };

  @override
  void initState() {
    super.initState();
    _loadCurrentLocation();
  }

  Future<void> _loadCurrentLocation() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      if (mounted && userDoc.exists) {
        setState(() {
          selectedCity = userDoc.data()?['city'];
          selectedArea = userDoc.data()?['area'];
        });
      }
    }
  }

  Future<void> _saveLocation() async {
    if (selectedCity == null || selectedArea == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select both city and area')),
      );
      return;
    }

    setState(() => isLoading = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .update({
          'city': selectedCity,
          'area': selectedArea,
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Location saved!')),
          );
          Navigator.pop(context, true);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
        );
      }
    } finally {
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Set Your Location',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFFc5aae6),
        elevation: 0,
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFc5aae6), Color(0xFFabc2e6)],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(30),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.9),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Column(
                    children: [
                      Icon(
                        Icons.location_on,
                        size: 60,
                        color: Color(0xFF9b7fd4),
                      ),
                      const SizedBox(height: 15),
                      Text(
                        'Find Hobby Friends Near You!',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'Set your location to discover and connect with people who share your interests nearby',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 30),

                // City Selector
                const Text(
                  'Select City',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 15),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      isExpanded: true,
                      value: selectedCity,
                      hint: const Text('Choose your city'),
                      icon: const Icon(Icons.arrow_drop_down),
                      items: cityAreas.keys.map((city) {
                        return DropdownMenuItem(
                          value: city,
                          child: Text(
                            city,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        );
                      }).toList(),
                      onChanged: (city) {
                        setState(() {
                          selectedCity = city;
                          selectedArea = null; // Reset area when city changes
                        });
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 25),

                // Area Selector
                const Text(
                  'Select Area',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 15),
                  decoration: BoxDecoration(
                    color: selectedCity == null
                        ? Colors.grey[300]
                        : Colors.white,
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      isExpanded: true,
                      value: selectedArea,
                      hint: Text(
                        selectedCity == null
                            ? 'Select city first'
                            : 'Choose your area',
                      ),
                      icon: const Icon(Icons.arrow_drop_down),
                      items: selectedCity != null
                          ? cityAreas[selectedCity]!.map((area) {
                        return DropdownMenuItem(
                          value: area,
                          child: Text(
                            area,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        );
                      }).toList()
                          : [],
                      onChanged: selectedCity != null
                          ? (area) {
                        setState(() {
                          selectedArea = area;
                        });
                      }
                          : null,
                    ),
                  ),
                ),
                const SizedBox(height: 30),

                // Preview
                if (selectedCity != null && selectedArea != null)
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.9),
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.location_on,
                          color: Color(0xFF9b7fd4),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Your Location',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey,
                                ),
                              ),
                              Text(
                                '$selectedArea, $selectedCity',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                const SizedBox(height: 30),

                // Save Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: isLoading ? null : _saveLocation,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: const Color(0xFF9b7fd4),
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                      elevation: 5,
                    ),
                    child: isLoading
                        ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                        : const Text(
                      'Save Location',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 15),

                // Privacy Note
                Container(
                  padding: const EdgeInsets.all(15),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        color: Colors.white,
                        size: 20,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Your exact address is never shared. Only your area is visible to other users.',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}