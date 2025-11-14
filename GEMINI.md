# Gemini Project Analysis: Anonymous Hubs Frontend

## Project Overview

The Anonymous Hubs frontend is a Flutter application designed for mobile, web, and desktop. It provides a platform for anonymous users to interact, share content, and communicate with empathy. The application is built with a feature-driven architecture, using the BLoC pattern (specifically Cubits) for state management. This application is a sub-app of the main `sfaisolutions` app.

## Core Architecture & State Management

The application is structured into three main layers within the `lib` directory:

*   **`core`**: Contains application-wide services, configuration, and enums.
    *   **`config`**: `ApiConfig` provides the base URLs for the backend API and WebSocket connections, with different URLs for release and debug modes.
    *   **`services`**: A set of API service classes (`AuthApiService`, `PostApiService`, etc.) that handle all HTTP requests to the backend. Each service is responsible for a specific domain of the API.
    *   **`enums`**: Defines application-wide enumerations like `VoteType`, `ReportStatus`, etc., with extensions for backend string value conversion.
*   **`features`**: This is the heart of the application, with each feature encapsulated in its own directory. The structure generally follows `feature -> presentation -> cubit/pages/widgets`.
    *   **State Management**: The application heavily relies on the `flutter_bloc` package, using **Cubits** for managing state within each feature. This provides a reactive and predictable way to handle UI updates based on user interactions and backend responses.
    *   **Dependency Injection**: The `main.dart` file sets up a `MultiRepositoryProvider` to make API services available throughout the widget tree, and a `MultiBlocProvider` to provide the main Cubits (`AuthCubit`, `FeedCubit`, etc.) to the application.
*   **`shared`**: Contains widgets that are used across multiple features, such as `UserActionsPopupMenuButton`.

## Key Features

### 1. Authentication (`features/auth`)

*   **Anonymous Authentication**: Users are authenticated anonymously. The `AuthCubit` handles the creation of anonymous users, retrieval of access tokens, and secure storage of the token using `flutter_secure_storage`.
*   **Session Management**: `AuthCubit` also manages the application's authentication state (`Authenticated`, `Unauthenticated`, `AuthFailure`, etc.) and uses an `AuthGate` widget to direct users to the appropriate screen (e.g., `UsernameSelectionPage` or `MainNavigationPage`).
*   **User Profile**: The `User` model in `features/auth/presentation/models/user_model.dart` represents the authenticated user's data.

### 2. Feed (`features/feed`)

*   **Post Display**: The `FeedWidget` displays a list of posts, with pagination handled by the `FeedCubit`.
*   **Post Interaction**: Each post in the feed is managed by its own `PostItemCubit`, which handles voting and deletion.
*   **Post Creation**: `CreatePostPage` allows users to create new posts, with the `CreatePostCubit` managing the state of the creation process.
*   **Post Details**: `PostDetailsPage` displays a single post and its comments. It uses a `CommentsCubit` to load and manage the comments for that post.

### 3. Chat (`features/chat`)

*   **Real-time Communication**: The chat feature uses WebSockets for real-time messaging. The `ChatRoomCubit` manages the WebSocket connection, message sending, and receiving.
*   **Chat Rooms**: The `ChatListPage` displays a list of the user's chat rooms and pending chat requests.
*   **Chat Initiation**: The `ChatInitiationCubit` handles the logic for starting a new chat or sending a chat request, depending on the target user's `chatAvailability` status.
*   **Data Models**: The chat feature has a comprehensive set of data models in `features/chat/data/models` for chat rooms, messages, requests, etc.

### 4. User Profile (`features/user_profile`)

*   **Profile Display**: `UserProfilePage` displays a user's profile information, including their posts and comments.
*   **User Interaction**: The `UserInteractionCubit` manages muting and blocking other users.
*   **Content Loading**: `UserProfileCubit` is responsible for fetching the user's profile data, posts, and comments.

### 5. Settings (`features/settings`)

*   **Data Management**: The `SettingsPage` provides options for data erasure (e.g., deleting all posts, comments, or chats), managed by the `DataErasureCubit`.
*   **Muted/Blocked Users**: The settings page also provides access to lists of muted and blocked users, managed by the `UserInteractionListsCubit`.
*   **Account Deletion**: Users can delete their accounts from the settings page.

## Navigation

*   **`MainNavigationPage`**: This is the main screen after authentication, containing a `BottomNavigationBar` to switch between the Feed, AI Chat, and Chat features.
*   **`AppDrawer`**: A drawer accessible from the `MainNavigationPage` provides access to the user's profile, settings, and other application-level pages.
*   **Routing**: Navigation is handled using `MaterialPageRoute`, with pages being pushed onto the navigation stack.

## API Interaction

*   **`core/services`**: All communication with the backend API is centralized in the service classes in this directory.
*   **`http` package**: The `http` package is used for making HTTP requests.
*   **`web_socket_channel`**: This package is used for WebSocket communication in the chat feature.
*   **OpenAPI**: The `api_docs.json` file provides an OpenAPI specification for the backend API, which serves as a reference for the frontend API services.
