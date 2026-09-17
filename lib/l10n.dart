/// Chinese-primary copy. English is secondary and appears in smaller captions.
class S {
  static const appName = '优选刷新';
  static const appNameEn = 'CF Prefer Refresh';

  static const home = '首页';
  static const clash = 'Clash';
  static const settings = '设置';
  static const help = '说明';

  static const rolePublisher = '发布者';
  static const roleSubscribe = '仅订阅';
  static const rolePublisherEn = 'Publisher';
  static const roleSubscribeEn = 'Subscribe-only';

  static const refresh = '刷新';
  static const refreshHint = '立刻在本机测速并上传优选 IP';
  static const testOnly = '仅测速';
  static const retryUpload = '重新上传上次结果';
  static const cancel = '取消';

  static const overwriteWarn =
      '多个设备向同一份优选列表上传会互相覆盖。请只让一台「发布者」在常用网络上刷新；其他设备保持「仅订阅」，Clash 继续用同一条 Cloudflare 订阅。';

  static const networkHint =
      '测速质量取决于此刻这台设备的网络（家里 Wi‑Fi、公司网络、手机流量结果都会不同）。刷新必须从当前网络当场测，而不是用 NAS 或 VPS 上预先算好的名单。';

  static const clashKeepsUrl =
      'Clash「更新订阅」只会拉取 edgetunnel 已经生成的节点，不会触发测速。测速和上传只发生在本应用点「刷新」时。';
}
