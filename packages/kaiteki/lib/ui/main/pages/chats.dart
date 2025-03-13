import "package:flutter/material.dart";
import "package:kaiteki/di.dart";
import "package:kaiteki/preferences/app_experiment.dart";
import "package:kaiteki/preferences/app_preferences.dart" as preferences;
import "package:kaiteki/ui/chats/chat_message.dart";
import "package:kaiteki/ui/chats/chat_target_list.dart";
import "package:kaiteki/ui/chats/compose_message_bar.dart";
import "package:kaiteki/ui/shared/common.dart";
import "package:kaiteki/ui/shared/dialogs/find_user_dialog.dart";
import "package:kaiteki/ui/shared/icon_landing_widget.dart";
import "package:kaiteki/ui/shared/posts/avatar_widget.dart";
import "package:kaiteki/utils/extensions.dart";
import "package:kaiteki_core/social.dart";
import "package:kaiteki_core/utils.dart";

class ChatsPage extends ConsumerStatefulWidget {
  const ChatsPage({super.key});

  @override
  ConsumerState<ChatsPage> createState() => _ChatsPageState();
}

class _ChatsPageState extends ConsumerState<ChatsPage> {
  ChatTarget? selectedChat;

  @override
  Widget build(BuildContext context) {
    if (!ref.watch(AppExperiment.chats.provider)) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const IconLandingWidget(
              icon: Icon(Icons.science_rounded),
              text: Text("Chats are experimental"),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                final notifier = ref.read(preferences.experiments);
                notifier.value = [...notifier.value, AppExperiment.chats];
              },
              child: Text(context.l10n.proceedButtonLabel),
            ),
          ],
        ),
      );
    }

    final adapter = ref.watch(adapterProvider);
    final chatAdapter = adapter.safeCast<ChatSupport>();
    if (chatAdapter == null || !chatAdapter.capabilities.supportsChat) {
      return Center(
        child: IconLandingWidget(
          icon: const Icon(Icons.forum_outlined),
          text: Text("Chats are not supported by $adapter"),
        ),
      );
    }

    final chatList = FutureBuilder<Iterable<ChatTarget>>(
      future: chatAdapter.getChats(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return centeredCircularProgressIndicator;

        final chats = snapshot.data!;

        return Stack(
          children: [
            ChatTargetList(
              chats: chats.toList(growable: false),
              onChatSelected: (chat) {
                setState(() => selectedChat = chat);
              },
              selectedChatId: selectedChat?.id,
            ),
            Positioned(
              right: kFloatingActionButtonMargin,
              bottom: kFloatingActionButtonMargin,
              child: FloatingActionButton(
                onPressed: () async {
                  await showDialog(
                    context: context,
                    builder: (_) => const FindUserDialog(),
                  );
                },
                tooltip: "Start a new chat",
                child: const Icon(Icons.add_rounded),
              ),
            ),
          ],
        );
      },
    );

    final chatView = selectedChat == null
        ? const Center(
            child: IconLandingWidget(
              icon: Icon(Icons.forum_rounded),
              text: Text("Select a chat to begin"),
            ),
          )
        : ChatView(chat: selectedChat!);

    return OrientationBuilder(
      builder: (context, orientation) {
        if (orientation == Orientation.landscape) {
          return Row(
            children: [
              SizedBox(width: 350, child: chatList),
              const VerticalDivider(),
              Expanded(child: chatView),
            ],
          );
        }

        return selectedChat == null
            ? chatList
            : ChatView(
                chat: selectedChat!,
                onBack: () => setState(() => selectedChat = null),
              );
      },
    );
  }
}

class ChatView extends ConsumerWidget {
  const ChatView({
    super.key,
    required this.chat,
    this.onBack,
  });

  final ChatTarget chat;
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final adapter = ref.watch(adapterProvider) as ChatSupport;
    final currentUser = ref.watch(currentAccountProvider)?.user;

    return Column(
      children: [
        AppBar(
          automaticallyImplyLeading: false,
          elevation: 0,
          leading: onBack.andThen(
            (callback) => IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: callback,
            ),
          ),
          title: InkWell(
            borderRadius: BorderRadius.circular(8),
            onTap: chat is DirectChat
                ? () => context.showUser((chat as DirectChat).recipient, ref)
                : null,
            child: Row(
              children: [
                _buildIcon(context, ref),
                const SizedBox(width: 16),
                DefaultTextStyle(
                  style: Theme.of(context).textTheme.titleMedium!,
                  child: _buildTitle(context, ref),
                ),
              ],
            ),
          ),
        ),
        const Divider(height: 1),
        Expanded(
          child: FutureBuilder<Iterable<ChatMessage>>(
            future: adapter.getChatMessages(chat),
            builder: (context, snapshot) {
              final data = snapshot.data;

              if (data == null) return centeredCircularProgressIndicator;

              final messages = data;

              if (messages.isEmpty) {
                return const Center(
                  child: IconLandingWidget(
                    icon: Icon(Icons.message_rounded),
                    text: Text("Looks empty here..."),
                  ),
                );
              }

              return ListView.builder(
                itemBuilder: (context, index) {
                  final item = messages.elementAt(index);
                  return Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: ChatMessageWidget(
                      message: item,
                      received: currentUser?.id != item.author.id,
                    ),
                  );
                },
                itemCount: messages.length,
                reverse: true,
              );
            },
          ),
        ),
        const Divider(height: 1),
        ComposeMessageBar(
          onSendMessage: (content, attachments) {},
        ),
      ],
    );
  }

  Widget _buildTitle(BuildContext context, WidgetRef ref) {
    final chat = this.chat;
    if (chat is DirectChat) {
      return Text.rich(chat.recipient.renderDisplayName(context, ref));
    }
    if (chat is GroupChat) {
      return Text(chat.name ?? chat.fallbackName);
    }

    return Text(chat.toString());
  }

  Widget _buildIcon(BuildContext context, WidgetRef ref) {
    final chat = this.chat;
    if (chat is DirectChat) {
      return AvatarWidget(chat.recipient, size: 32);
    }
    if (chat is GroupChat) {
      return CircleAvatar(
        radius: 16,
        child: Text(
          chat.name!.substring(0, 1).toUpperCase(),
        ),
      );
    }
    return const SizedBox();
  }
}
