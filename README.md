# Defndr

### UPDATE: MAY 2025 
---
**Defndr is back on the iOS App Store!**

We're excited to announce Defndr is back and better than ever. You might have noticed a pause in our repository updates. This was a temporary measure to protect our intellectual property from unauthorized copying and to ensure the unique value of Defndr remains intact. We're committed to maintaining the integrity of our work and providing you with the best SMS spam protection.

Thank you for your understanding and continued support!

---
###

Welcome to the Defndr GitHub repository! This repository showcases the core machine learning components that power the Defndr iOS app, an SMS spam filter designed to protect users from unwanted messages while prioritizing privacy and security.

## Purpose of This Repository

The purpose of this repository is to provide transparency into the inner workings of Defndr. By sharing the machine learning model and vocabulary used for spam detection, we aim to demonstrate:
- **How Defndr Works**: The app uses advanced natural language processing (NLP) to classify SMS messages as spam or not spam, all processed on-device to ensure your data never leaves your phone.
- **Open Source and Secure**: We believe in being open about our technology to build trust with our users. This repository shows that Defndr is built with security and privacy in mind.
- **Educational Insight**: For users and developers interested in the technical details, this repository offers a glimpse into the ML technology behind Defndr.

## Important Notice

**This code and model are for informational purposes only.** The contents of this repository, including the `SpamClassifier.mlmodel` and `vocabulary.json`, are the intellectual property of the Defndr team. You are welcome to view and learn from the code, but **you are not permitted to use, copy, modify, distribute, or integrate this model or code into your own projects** without explicit permission from the Defndr team. This repository is shared to promote transparency and trust, not for reuse.

## Components

- **`SpamClassifier.mlmodel`**: The Core ML model used for spam detection in Defndr. It analyzes SMS messages and classifies them as spam or not spam based on patterns identified through NLP.
- **`vocabulary.json`**: A vocabulary file containing words commonly associated with spam messages. This file is used to vectorize incoming messages before they are passed to the model for classification.

## How It Works

Defndr uses the `SpamClassifier.mlmodel` to process incoming SMS messages in real-time on your device. Here’s a brief overview of the process:
1. **Message Vectorization**: The app converts each incoming message into a numerical vector using the vocabulary in `vocabulary.json`. This vector represents the presence or absence of spam-related words.
2. **Spam Classification**: The vector is passed to the `SpamClassifier` model, which predicts whether the message is spam or not spam.
3. **On-Device Processing**: All processing happens on your device using Apple’s IdentityLookup framework, ensuring your messages never leave your phone.
4. **Action**: If a message is classified as spam, it is moved to the Junk folder with a "maybe junk:" label.

For more details on the implementation, you can view the `MessageFilterExtension.swift` file in the Defndr app source code (not included in this repository).

## Security and Privacy

- **On-Device Processing**: Defndr processes all messages locally on your device, ensuring your data remains private and secure.
- **No Data Sharing**: The app does not send your messages to any external servers or third parties.
- **Open Source Transparency**: By sharing these components, we aim to show that Defndr is built with user privacy and security as top priorities.

## Learn More

To learn more about Defndr and its features, visit the app’s "Learn More" section in the iOS app, where you can find additional details about how the app works and its commitment to privacy.

## Contact

If you have any questions about Defndr or this repository, please contact the Defndr team at apps@dro1d.org.

---

**Note**: This repository is for transparency and educational purposes only. Unauthorized use of the code or model is strictly prohibited.
