import 'package:flutter/material.dart';

class TutorialPage extends StatefulWidget {
  final VoidCallback onGetStarted;

  const TutorialPage({super.key, required this.onGetStarted});

  @override
  State<TutorialPage> createState() => _TutorialPageState();
}

class _TutorialPageState extends State<TutorialPage> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<Map<String, String>> tutorialContents = [
    {
      "title": "What is a Home Energy Audit?",
      "description": 
          "A home energy audit is a comprehensive assessment that evaluates how much energy your home consumes and identifies opportunities to improve energy efficiency. "
          "Think of it as a health check-up for your house. By pinpointing areas where energy is wasted—such as poor insulation, air leaks, outdated appliances, and inefficient heating and cooling systems—homeowners can make targeted improvements that lead to significant energy savings.\n\n"
          "Energy audits typically examine key components of the building envelope, including walls, ceilings, floors, windows, and doors. They also assess heating, ventilation, air conditioning (HVAC) systems, water heating, and major appliances. "
          "A thorough audit will not only highlight inefficiencies but also prioritize upgrades based on cost-effectiveness.\n\n"
          "According to the U.S. Department of Energy (DOE), homeowners who follow through on audit recommendations can cut their energy usage by 5% to 30%, reducing monthly utility bills and extending the lifespan of their home’s systems."
    },
    {
      "title": "Why Is a Home Energy Audit Important?",
      "description":
          "An energy audit is not just a luxury—it's a practical tool that can have a profound impact on your household’s budget, comfort, and environmental footprint. "
          "Many homes, especially older constructions, suffer from hidden inefficiencies. Small cracks in windows, insufficient attic insulation, or outdated HVAC systems may seem insignificant but can cumulatively account for a large portion of energy waste.\n\n"
          "The Environmental Protection Agency (EPA) estimates that the average U.S. household spends more than \$2,000 annually on energy bills, nearly half of which goes toward heating and cooling. Through proper energy auditing and efficiency upgrades, households can significantly lower these costs, with annual savings of up to \$500 or more.\n\n"
          "Beyond financial benefits, a well-executed energy audit enhances indoor environments—reducing humidity, preventing mold growth, and stabilizing indoor temperatures. Improving home energy performance also helps cut greenhouse gas emissions—one of the most impactful actions an individual can take to combat climate change."
    },
    {
      "title": "How Our App Helps You",
      "description":
          "Our Home Energy Audit app is designed with simplicity and efficiency at its core. We understand that professional audits can be expensive and time-consuming. That’s why we created a tool that democratizes energy auditing, making it available anytime, anywhere.\n\n"
          "Through an intuitive, user-friendly interface, our app guides you through the essential steps of assessing your home’s energy performance. With just a few photos, simple inputs about your appliances and building materials, and guided questions, you can generate a detailed, personalized energy report within minutes.\n\n"
          "What We Offer:\n"
          "• Step-by-step guidance—even if you’re not an energy expert.\n"
          "• Instant reports—get actionable insights immediately.\n"
          "• Personalized recommendations—tailored advice based on your home.\n"
          "• Data visualization—charts and graphs help you easily understand your energy use.\n\n"
          "By empowering homeowners with knowledge and tools, we enable smarter decisions that lead to lower costs, improved comfort, and a greener future."
    },
    {
      "title": "The Benefits of Saving Energy",
      "description":
          "Saving energy isn’t just about reducing utility bills—it’s about investing in your home, your comfort, and the planet. Energy-efficient homes are proven to be more comfortable, safer, and healthier. They also tend to have higher property values and are more attractive to buyers.\n\n"
          "Energy efficiency improvements such as adding insulation, sealing air leaks, or upgrading to ENERGY STAR® appliances can yield significant returns. A report by the U.S. Department of Energy highlights that every \$1 invested in home energy efficiency improvements can generate up to \$2 in energy savings.\n\n"
          "In addition to financial gains, energy efficiency has environmental benefits. Residential energy use accounts for roughly 20% of U.S. greenhouse gas emissions. Reducing your home’s energy consumption means directly lowering your carbon footprint and contributing to global sustainability efforts.\n\n"
          "Key Takeaways:\n"
          "• Lower costs—shrink your monthly utility bills.\n"
          "• Increased home value—energy-efficient homes sell for 2% to 5% more.\n"
          "• Environmental impact—reduce your household’s contribution to climate change.\n"
          "• Better comfort—no more drafts and inconsistent temperatures.\n\n"
          "Making your home more energy-efficient is a smart financial decision and a meaningful lifestyle upgrade."
    }
  ];


  void _nextPage() {
    if (_currentPage < tutorialContents.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.ease,
      );
    } else {
      widget.onGetStarted();
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemCount: tutorialContents.length,
                onPageChanged: (index) {
                  setState(() {
                    _currentPage = index;
                  });
                },
                itemBuilder: (context, index) {
                  final content = tutorialContents[index];
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          content['title']!,
                          style: const TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 24),
                        Expanded(
                          child: SingleChildScrollView(
                            child: Text(
                              content['description']!,
                              style: const TextStyle(
                                fontSize: 18,
                                color: Colors.white70,
                                height: 1.5,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildDotsIndicator(),
                  ElevatedButton(
                    onPressed: _nextPage,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    ),
                    child: Text(_currentPage == tutorialContents.length - 1 ? 'Get Started' : 'Next'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDotsIndicator() {
    return Row(
      children: List.generate(
        tutorialContents.length,
        (index) => Container(
          margin: const EdgeInsets.symmetric(horizontal: 4.0),
          width: _currentPage == index ? 12.0 : 8.0,
          height: _currentPage == index ? 12.0 : 8.0,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: _currentPage == index ? Colors.green : Colors.white24,
          ),
        ),
      ),
    );
  }
}