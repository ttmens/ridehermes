class Validators {
  static String? phone(String? value) {
    if (value == null || value.isEmpty) {
      return '请输入手机号';
    }
    if (value.length != 11 || !RegExp(r'^1[3-9]\d{9}$').hasMatch(value)) {
      return '请输入有效的手机号';
    }
    return null;
  }

  static String? password(String? value) {
    if (value == null || value.isEmpty) {
      return '请输入密码';
    }
    if (value.length < 6) {
      return '密码至少6位';
    }
    return null;
  }

  static String? required(String? value, {String fieldName = '此字段'}) {
    if (value == null || value.isEmpty) {
      return '$fieldName不能为空';
    }
    return null;
  }
}
