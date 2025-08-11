/// 本地 Mock 服务，实际回复由 FlowNode 决定，Service 可留空
class AssistantService {
  Future<String> getReply(String input) async {
    // 只是模拟延迟，实际文本由 FlowNode 管理
    await Future.delayed(const Duration(milliseconds: 300));
    return '';
  }
}
