import 'package:body_part_selector/body_part_selector.dart';

/// Maps granular [BodyParts] fields → SACA painLocation coarse strings.
List<String> bodyPartsToPainLocation(BodyParts bp) {
  final parts = <String>{};
  if (bp.head || bp.neck || bp.vestibular) {
    parts.add('Head');
  }
  if (bp.upperBody || bp.leftShoulder || bp.rightShoulder) {
    parts.add('Chest');
  }
  if (bp.abdomen) {
    parts.add('Abdominal');
  }
  if (bp.lowerBody) {
    parts.add('Hip');
  }
  if (bp.leftShoulder   || bp.rightShoulder  ||
      bp.leftUpperArm   || bp.rightUpperArm  ||
      bp.leftElbow      || bp.rightElbow     ||
      bp.leftLowerArm   || bp.rightLowerArm  ||
      bp.leftHand       || bp.rightHand) {
    parts.add('Arm');
  }
  if (bp.leftUpperLeg  || bp.rightUpperLeg  ||
      bp.leftKnee      || bp.rightKnee      ||
      bp.leftLowerLeg  || bp.rightLowerLeg  ||
      bp.leftFoot      || bp.rightFoot) {
    parts.add('Leg');
  }
  return parts.toList();
}

/// Restores [BodyParts] from SACA coarse painLocation strings.
BodyParts painLocationToBodyParts(List<String> locs) {
  return BodyParts(
    head:          locs.contains('Head'),
    neck:          locs.contains('Head'),
    upperBody:     locs.contains('Chest') || locs.contains('Back'),
    abdomen:       locs.contains('Abdominal'),
    lowerBody:     locs.contains('Hip')   || locs.contains('Back'),
    leftUpperArm:  locs.contains('Arm'),
    rightUpperArm: locs.contains('Arm'),
    leftUpperLeg:  locs.contains('Leg'),
    rightUpperLeg: locs.contains('Leg'),
  );
}

/// Matches a tapped GLB mesh name to a [BodyParts] field and toggles it.
/// Exact-name cases at the top handle the HumanModel.glb mesh hierarchy;
/// the keyword fallback handles any renamed variant.
BodyParts togglePartByMeshName(BodyParts current, String meshName) {
  final n = meshName.toLowerCase().trim();
  if (n.isEmpty || n == 'unknown') return current;

  // ── Exact matches for HumanModel.glb ─────────────────────────────────
  // Mesh hierarchy: Body | Head | Left Arm | Right Arm | Leg
  if (n == 'body') {
    return current.copyWith(upperBody: !current.upperBody);
  }
  if (n == 'head') {
    return current.copyWith(head: !current.head);
  }
  if (n == 'left arm') {
    return current.copyWith(leftUpperArm: !current.leftUpperArm);
  }
  if (n == 'right arm') {
    return current.copyWith(rightUpperArm: !current.rightUpperArm);
  }
  // Single "Leg" mesh covers both legs — toggle bilateral representative fields.
  if (n == 'leg') {
    return current.copyWith(
      leftUpperLeg:  !current.leftUpperLeg,
      rightUpperLeg: !current.rightUpperLeg,
    );
  }

  // ── Keyword fallback for custom/renamed meshes ────────────────────────
  // Head region
  if (n.contains('head') || n.contains('skull') || n.contains('face')) {
    return current.copyWith(head: !current.head);
  }
  if (n.contains('neck')) {
    return current.copyWith(neck: !current.neck);
  }

  // Torso region
  if (n.contains('torso') || n.contains('chest') || n.contains('upper_body')) {
    return current.copyWith(upperBody: !current.upperBody);
  }
  if (n.contains('abdomen') || n.contains('belly') || n.contains('stomach')) {
    return current.copyWith(abdomen: !current.abdomen);
  }
  if (n.contains('hip') || n.contains('pelvis') || n.contains('lower_body')) {
    return current.copyWith(lowerBody: !current.lowerBody);
  }

  // Arms — check left/right prefix first, then part name
  if (n.contains('left')) {
    if (n.contains('shoulder')) {
      return current.copyWith(leftShoulder:  !current.leftShoulder);
    }
    if (n.contains('upper_arm') || n.contains('upperarm')) {
      return current.copyWith(leftUpperArm:  !current.leftUpperArm);
    }
    if (n.contains('elbow')) {
      return current.copyWith(leftElbow:     !current.leftElbow);
    }
    if (n.contains('forearm') || n.contains('lower_arm')) {
      return current.copyWith(leftLowerArm:  !current.leftLowerArm);
    }
    if (n.contains('hand')) {
      return current.copyWith(leftHand:      !current.leftHand);
    }
    if (n.contains('thigh') || n.contains('upper_leg')) {
      return current.copyWith(leftUpperLeg:  !current.leftUpperLeg);
    }
    if (n.contains('knee')) {
      return current.copyWith(leftKnee:      !current.leftKnee);
    }
    if (n.contains('shin') || n.contains('calf') || n.contains('lower_leg')) {
      return current.copyWith(leftLowerLeg:  !current.leftLowerLeg);
    }
    if (n.contains('foot')) {
      return current.copyWith(leftFoot:      !current.leftFoot);
    }
  }
  if (n.contains('right')) {
    if (n.contains('shoulder')) {
      return current.copyWith(rightShoulder: !current.rightShoulder);
    }
    if (n.contains('upper_arm') || n.contains('upperarm')) {
      return current.copyWith(rightUpperArm: !current.rightUpperArm);
    }
    if (n.contains('elbow')) {
      return current.copyWith(rightElbow:    !current.rightElbow);
    }
    if (n.contains('forearm') || n.contains('lower_arm')) {
      return current.copyWith(rightLowerArm: !current.rightLowerArm);
    }
    if (n.contains('hand')) {
      return current.copyWith(rightHand:     !current.rightHand);
    }
    if (n.contains('thigh') || n.contains('upper_leg')) {
      return current.copyWith(rightUpperLeg: !current.rightUpperLeg);
    }
    if (n.contains('knee')) {
      return current.copyWith(rightKnee:     !current.rightKnee);
    }
    if (n.contains('shin') || n.contains('calf') || n.contains('lower_leg')) {
      return current.copyWith(rightLowerLeg: !current.rightLowerLeg);
    }
    if (n.contains('foot')) {
      return current.copyWith(rightFoot:     !current.rightFoot);
    }
  }

  // Fallback — bilateral mesh named just "arm" or "leg" with no side prefix
  if (n.contains('arm') && !n.contains('fore')) {
    return current.copyWith(
      leftUpperArm:  !current.leftUpperArm,
      rightUpperArm: !current.rightUpperArm,
    );
  }
  if (n.contains('leg') || n.contains('thigh')) {
    return current.copyWith(
      leftUpperLeg:  !current.leftUpperLeg,
      rightUpperLeg: !current.rightUpperLeg,
    );
  }

  return current; // no recognised keyword
}

/// Human-readable labels per [BodyParts] field for the chip summary strip.
List<String> selectedPartDisplayNames(BodyParts bp) {
  return <String>[
    if (bp.head)          'Head',
    if (bp.neck)          'Neck',
    if (bp.vestibular)    'Vestibular',
    if (bp.leftShoulder)  'L. Shoulder',
    if (bp.rightShoulder) 'R. Shoulder',
    if (bp.leftUpperArm)  'L. Upper arm',
    if (bp.rightUpperArm) 'R. Upper arm',
    if (bp.leftElbow)     'L. Elbow',
    if (bp.rightElbow)    'R. Elbow',
    if (bp.leftLowerArm)  'L. Lower arm',
    if (bp.rightLowerArm) 'R. Lower arm',
    if (bp.leftHand)      'L. Hand',
    if (bp.rightHand)     'R. Hand',
    if (bp.upperBody)     'Chest / back',
    if (bp.abdomen)       'Abdomen',
    if (bp.lowerBody)     'Hip / lower back',
    // Legs are a single mesh — show as one undifferentiated "Leg" entry.
    if (bp.leftUpperLeg  || bp.rightUpperLeg  ||
        bp.leftKnee      || bp.rightKnee      ||
        bp.leftLowerLeg  || bp.rightLowerLeg  ||
        bp.leftFoot      || bp.rightFoot)  'Leg',
  ];
}
