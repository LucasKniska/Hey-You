
import 'package:hey_you/Data/models/PreviousMatch.dart';
import 'package:intl/intl.dart';
import '../../Data/models/ScheduledMatch.dart';

/// Example for how a text string file would look
class TTexts {

  /// OnBoarding texts
  static const String onBoardingTitle0 = 'Welcome to Hey You!';
  static const String onBoardingTitle1 = 'Connect With Real People In The Real World';
  static const String onBoardingUnder1 = 'Hey You helps you create genuine connections with people nearby, transforming online '
      'interactions into real-world friendships.';
  static const String onBoardingTitle2 = 'How Hey You Works:';

  static const String onBoardingCard1 = 'Create Your Profile';
  static const String onBoardingCard2 = 'Discover People Nearby';
  static const String onBoardingCard3 = 'Form Connections in Real Life';

  static const String onBoardingUnderCard1 = 'Set up your profile with your interests, personality, and what you are looking to connect about.';
  static const String onBoardingUnderCard2 = 'Discover people in your area who share your interests and want to connect.';
  static const String onBoardingUnderCard3 = 'Meet right away or have us automatically plan an event!';

  static const String onBoardingSignIn = 'Sign In';
  static const String onBoardingSignUp = 'Sign Up';


  /// Sign In and Log In Texts
  static const String loginTitle1 = 'Welcome Back to Hey You!';
  static const String loginUnder1 = 'Sign In to Connect With People Nearby';

  static const String email = 'Email';
  static const String password = 'Password';
  static const String userName = 'Username';
  static const String login = 'Sign In';
  static const String signUp = 'Sign Up';

  static const String noAccount = 'Don\'t have an account yet?: ';
  static const String hasAccount = 'Already have an account?: ';

  static const String rememberMe = 'Remember Me';
  static const String forgotPassword = 'Forgot Password?';

  static const String createAccount = 'Create an Account';
  static const String createAccountUnder = 'Join Hey You to connect with people nearby';
  static const String termsOfService1 = 'I agree to the ';
  static const String termsOfService2 = 'Terms of Service';

  static const String firstName = 'First Name';
  static const String lastName = 'Last Name';


  /// Quiz Page Texts
  static const String HeyYou = 'Hey You';
  static const String quizTitle = 'Please Tell Us A Little Bit About Yourself:';
  static const String quizUnder = 'This information is necessary to connect you to others with similar interests.';

  static const String submitQuiz = 'Submit Quiz';


  /// Connections Page Texts
  static const String connectionsTitleCard = 'This shows your scheduled meet ups and previous connections:';
  static const String connectionsDescriptionCard = 'Here you can reach out to previous connections and see your scheduled connections.';
  static const String scheduledMeetUps = 'Scheduled Meet Ups';
  static const String previousConnections = 'Previous Connections';

  static String previousConnectionDateDetails(DateTime date, String place) {
    String formatted = DateFormat('MMMM, d y').format(date);
    return 'You connected on $formatted @ $place';
  }

  static String previousConnectionUserDetails(PreviousMatch match){
    return "${match.userData["user1"]?["userName"]} - ${match.related[0]}, ${match.related[1]}";
  }

  static String scheduledConnectionDateDetails(DateTime date){
    String formatted = DateFormat('MMMM, d y').format(date);
    return 'You matched on $formatted!';
  }

  static String scheduledConnectionUserDetails(ScheduledMatch match){
    String formatted = DateFormat('MMMM, d y \'at\' h:mm a').format(match.meetingTime);

    return "${match.userName[0]} - $formatted @ ${match.meetingPlace['title']}";
  }


  /// Profile Page Texts
  static const String publicBioHint = 'List character traits others should know here!';

}