// Inline illustrations in the Kernel visual language: forest line art on a
// soft sage field, paper fills, and amber only for sound. No text inside
// the drawings, so they never need translating.

const _kernelMark =
    '<path d="M256 36 C300 36 392 132 392 258 C392 384 330 476 256 476 '
    'C182 476 120 384 120 258 C120 132 212 36 256 36 Z" fill="#234C38"/>'
    '<path d="M256 36 C212 36 120 132 120 258 C120 384 182 476 256 476 Z" '
    'fill="#2E6249"/>'
    '<path d="M256 100 L256 128 L270 149.7 L222 171.3 L278 193 L198 214.7 '
    'L296 236.3 L186 258 L302 279.7 L194 301.3 L284 323 L216 344.7 '
    'L272 366.3 L256 388 L256 416" fill="none" stroke="#D9A441" '
    'stroke-width="28" stroke-linecap="round" stroke-linejoin="round"/>';

/// The brand kernel centred on ([cx], [cy]) with the given height.
String _kernel(double cx, double cy, double height) {
  final s = height / 440;
  final tx = cx - 256 * s;
  final ty = cy - 256 * s;
  return '<g transform="translate(${tx.toStringAsFixed(2)} '
      '${ty.toStringAsFixed(2)}) scale(${s.toStringAsFixed(4)})">'
      '$_kernelMark</g>';
}

const _open =
    '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 240 160">'
    '<ellipse cx="120" cy="86" rx="100" ry="66" fill="#E6EFE4"/>';
const _close = '</svg>';
const _stroke =
    'stroke="#234C38" stroke-width="5" stroke-linecap="round" '
    'stroke-linejoin="round"';
const _line = 'fill="none" $_stroke';
const _amberLine =
    'fill="none" stroke="#D9A441" stroke-width="5" stroke-linecap="round"';

/// Sound arcs radiating to the right of ([x], [y]).
String _waves(double x, double y) =>
    '<path d="M$x ${y - 12} Q${x + 9} $y $x ${y + 12}" $_amberLine/>'
    '<path d="M${x + 11} ${y - 22} Q${x + 26} $y ${x + 11} ${y + 22}" '
    '$_amberLine opacity="0.7"/>';

abstract final class KernelIllustrations {
  /// No sacks yet.
  static final String sacks =
      '$_open'
      '<path d="M92 66 C80 80 74 104 78 122 C81 134 94 140 120 140 '
      'C146 140 159 134 162 122 C166 104 160 80 148 66 Z" fill="#FFFDF8" '
      '$_stroke/>'
      '<path d="M106 64 L102 44 L113 52 L120 40 L127 52 L138 44 L134 64" '
      'fill="#FFFDF8" $_stroke/>'
      '<rect x="100" y="60" width="40" height="10" rx="5" fill="#D9A441"/>'
      '${_kernel(120, 104, 34)}'
      '${_waves(172, 100)}'
      '<path d="M52 140 L188 140" stroke="#234C38" stroke-width="3" '
      'stroke-linecap="round" opacity="0.35"/>'
      '$_close';

  /// No containers yet (household).
  static final String container =
      '$_open'
      '<rect x="90" y="38" width="60" height="16" rx="7" fill="#234C38"/>'
      '<path d="M96 54 L96 124 C96 134 104 140 114 140 L126 140 '
      'C136 140 144 134 144 124 L144 54" fill="#FFFDF8" $_stroke/>'
      '<path d="M99 96 L141 96 L141 124 C141 132 134 137 126 137 L114 137 '
      'C106 137 99 132 99 124 Z" fill="#CFDECB"/>'
      '<ellipse cx="110" cy="112" rx="3.5" ry="5.5" fill="#D9A441"/>'
      '<ellipse cx="122" cy="120" rx="3.5" ry="5.5" fill="#D9A441"/>'
      '<ellipse cx="132" cy="108" rx="3.5" ry="5.5" fill="#D9A441"/>'
      '<rect x="106" y="66" width="28" height="18" rx="5" fill="#E6EFE4" '
      'stroke="#234C38" stroke-width="3"/>'
      '${_waves(156, 96)}'
      '$_close';

  /// No lots yet (buyer deliveries).
  static final String lots =
      '$_open'
      '<rect x="52" y="62" width="96" height="54" rx="9" fill="#FFFDF8" '
      '$_stroke/>'
      '<path d="M148 80 L171 80 L186 98 L186 116 L148 116 Z" '
      'fill="#CFDECB" $_stroke/>'
      '<path d="M155 87 L168 87 L177 98 L155 98 Z" fill="#FFFDF8"/>'
      '<circle cx="80" cy="120" r="12" fill="#234C38"/>'
      '<circle cx="80" cy="120" r="4" fill="#FFFDF8"/>'
      '<circle cx="164" cy="120" r="12" fill="#234C38"/>'
      '<circle cx="164" cy="120" r="4" fill="#FFFDF8"/>'
      '${_kernel(100, 89, 30)}'
      '<path d="M36 140 L204 140" stroke="#234C38" stroke-width="3" '
      'stroke-linecap="round" stroke-dasharray="10 10" opacity="0.4"/>'
      '$_close';

  /// Nothing to inspect / no inspections yet.
  static final String inspection =
      '$_open'
      '${_kernel(78, 110, 26)}'
      '${_kernel(100, 124, 22)}'
      '${_kernel(186, 70, 24)}'
      '<circle cx="128" cy="76" r="34" fill="#FFFDF8" stroke="#234C38" '
      'stroke-width="6"/>'
      '${_kernel(128, 76, 38)}'
      '<path d="M153 101 L178 126" stroke="#234C38" stroke-width="12" '
      'stroke-linecap="round"/>'
      '$_close';

  /// No research recordings yet.
  static final String recordings =
      '$_open'
      '<rect x="104" y="30" width="32" height="62" rx="16" fill="#FFFDF8" '
      '$_stroke/>'
      '<path d="M112 50 L128 50 M112 62 L128 62 M112 74 L128 74" '
      'stroke="#CFDECB" stroke-width="4" stroke-linecap="round"/>'
      '<path d="M90 74 C90 112 150 112 150 74" $_line/>'
      '<path d="M120 102 L120 124 M102 128 L138 128" $_line/>'
      '<path d="M58 86 L58 98 M70 76 L70 108 M82 84 L82 100 '
      'M158 84 L158 100 M170 72 L170 112 M182 86 L182 98" '
      'stroke="#D9A441" stroke-width="6" stroke-linecap="round"/>'
      '$_close';

  /// Empty queue / nothing assigned.
  static final String queue =
      '$_open'
      '<rect x="80" y="34" width="80" height="108" rx="12" fill="#FFFDF8" '
      '$_stroke/>'
      '<rect x="102" y="26" width="36" height="16" rx="6" fill="#234C38"/>'
      '<circle cx="100" cy="66" r="6" fill="#D9A441"/>'
      '<path d="M114 66 L144 66" $_line/>'
      '<circle cx="100" cy="90" r="6" fill="#CFDECB"/>'
      '<path d="M114 90 L138 90" $_line/>'
      '<circle cx="100" cy="114" r="6" fill="#CFDECB"/>'
      '<path d="M114 114 L132 114" $_line/>'
      '$_close';

  /// Harvests (farmer).
  static final String harvest =
      '$_open'
      '<path d="M78 140 C80 110 84 80 92 46" $_line/>'
      '<ellipse cx="86" cy="58" rx="6" ry="11" fill="#D9A441" '
      'transform="rotate(-30 86 58)"/>'
      '<ellipse cx="99" cy="62" rx="6" ry="11" fill="#D9A441" '
      'transform="rotate(30 99 62)"/>'
      '<ellipse cx="83" cy="78" rx="6" ry="11" fill="#D9A441" '
      'transform="rotate(-30 83 78)"/>'
      '<ellipse cx="96" cy="82" rx="6" ry="11" fill="#D9A441" '
      'transform="rotate(30 96 82)"/>'
      '<ellipse cx="91" cy="42" rx="5" ry="10" fill="#D9A441"/>'
      '<path d="M120 76 C110 90 106 108 108 122 C110 134 120 140 142 140 '
      'C164 140 174 134 176 122 C178 108 174 90 164 76 Z" fill="#FFFDF8" '
      '$_stroke/>'
      '<rect x="122" y="70" width="40" height="10" rx="5" fill="#234C38"/>'
      '${_kernel(142, 110, 30)}'
      '$_close';

  /// QR label scanning.
  static final String qr =
      '$_open'
      '<rect x="78" y="36" width="84" height="100" rx="14" fill="#FFFDF8" '
      '$_stroke/>'
      '<path d="M92 62 L92 52 L102 52 M138 52 L148 52 L148 62 '
      'M148 110 L148 120 L138 120 M102 120 L92 120 L92 110" $_line/>'
      '${_kernel(120, 86, 40)}'
      '<path d="M84 86 L156 86" stroke="#D9A441" stroke-width="4" '
      'stroke-linecap="round" opacity="0.9"/>'
      '$_close';

  /// Onboarding 1: audio stays on the phone.
  static final String privacy =
      '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 240 180">'
      '<circle cx="120" cy="92" r="82" fill="#E6EFE4"/>'
      '<rect x="80" y="18" width="80" height="148" rx="16" fill="#FFFDF8" '
      '$_stroke/>'
      '<rect x="108" y="28" width="24" height="5" rx="2.5" fill="#CFDECB"/>'
      '<path d="M120 52 L146 62 L146 88 C146 106 135 118 120 126 '
      'C105 118 94 106 94 88 L94 62 Z" fill="#234C38"/>'
      '<path d="M104 90 L110 90 L114 80 L120 100 L126 74 L130 92 L136 90" '
      'fill="none" stroke="#D9A441" stroke-width="4" stroke-linecap="round" '
      'stroke-linejoin="round"/>'
      '<path d="M176 46 C176 38 184 34 190 38 C194 30 208 32 208 42 '
      'C214 42 216 52 210 54 L180 54 C174 54 172 46 176 46 Z" '
      'fill="#FFFDF8" stroke="#6E7B72" stroke-width="3"/>'
      '<path d="M178 30 L210 62" stroke="#9B2C1F" stroke-width="4" '
      'stroke-linecap="round"/>'
      '${_kernel(52, 140, 22)}'
      '${_kernel(68, 152, 18)}'
      '$_close';

  /// Onboarding 2: phone flat against the sack, quiet room, 2 seconds.
  static final String howToScan =
      '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 240 180">'
      '<circle cx="120" cy="96" r="80" fill="#E6EFE4"/>'
      '<path d="M66 64 C52 82 46 112 50 134 C53 150 70 158 104 158 '
      'C138 158 155 150 158 134 C162 112 156 82 142 64 Z" fill="#FFFDF8" '
      '$_stroke/>'
      '<path d="M82 62 L78 40 L92 50 L104 36 L116 50 L130 40 L126 62" '
      'fill="#FFFDF8" $_stroke/>'
      '<rect x="76" y="58" width="56" height="10" rx="5" fill="#D9A441"/>'
      '<g transform="rotate(-8 104 112)">'
      '<rect x="84" y="80" width="44" height="72" rx="9" fill="#234C38"/>'
      '<rect x="89" y="88" width="34" height="54" rx="5" fill="#2E6249"/>'
      '<path d="M94 116 L99 116 L102 108 L106 124 L110 102 L114 120 '
      'L118 116" fill="none" stroke="#D9A441" stroke-width="3" '
      'stroke-linecap="round" stroke-linejoin="round"/>'
      '</g>'
      '<circle cx="192" cy="58" r="22" fill="#FFFDF8" stroke="#234C38" '
      'stroke-width="5"/>'
      '<path d="M192 58 L192 44 M192 58 L202 64" stroke="#234C38" '
      'stroke-width="5" stroke-linecap="round"/>'
      '<path d="M186 30 L198 30" stroke="#234C38" stroke-width="5" '
      'stroke-linecap="round"/>'
      '<path d="M192 58 L192 36 A22 22 0 0 1 211 47 Z" fill="#D9A441" '
      'opacity="0.55"/>'
      '<path d="M174 116 L182 116 L192 106 L192 138 L182 128 L174 128 Z" '
      'fill="#FFFDF8" stroke="#234C38" stroke-width="4" '
      'stroke-linejoin="round"/>'
      '<path d="M200 114 L212 130 M212 114 L200 130" stroke="#234C38" '
      'stroke-width="4" stroke-linecap="round"/>'
      '$_close';
}
