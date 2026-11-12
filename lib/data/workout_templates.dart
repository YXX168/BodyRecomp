import '../models/daily_workout.dart';
import '../models/recomp_models.dart';

// Reference routines supplied by the user, not a compulsory prescription.
const defaultTemplates = [
  WorkoutTemplate(
      id: 'push',
      name: '推 · 胸肩三头',
      note: '练后参考：爬坡快走 20 分钟；坡度 8–12，速度 4.5–5.0 km/h。',
      exercises: [
        Exercise(
            name: '平板卧推',
            muscles: ['胸', '肱三头'],
            muscleTarget: '胸部',
            sets: 4,
            reps: '8-10',
            rest: '90s'),
        Exercise(
            name: '上斜器械推胸',
            muscles: ['胸'],
            muscleTarget: '上胸',
            sets: 4,
            reps: '10-12',
            rest: '90s'),
        Exercise(
            name: '坐姿器械肩推',
            muscles: ['肩'],
            muscleTarget: '前束 / 中束',
            sets: 4,
            reps: '8-12',
            rest: '90s'),
        Exercise(
            name: '哑铃侧平举',
            muscles: ['肩'],
            muscleTarget: '中束',
            sets: 5,
            reps: '12-15',
            rest: '60s',
            isStar: true),
        Exercise(
            name: '龙门架绳索下压',
            muscles: ['肱三头'],
            muscleTarget: '',
            sets: 3,
            reps: '12-15',
            rest: '60s'),
      ]),
  WorkoutTemplate(
      id: 'pull',
      name: '拉 · 背后束二头',
      note: '练后参考：爬坡快走 20 分钟；疲劳时可跳过，直接拉伸。',
      exercises: [
        Exercise(
            name: '宽握高位下拉',
            muscles: ['背'],
            muscleTarget: '背阔肌',
            sets: 4,
            reps: '8-10',
            rest: '90s'),
        Exercise(
            name: '坐姿器械划船',
            muscles: ['背'],
            muscleTarget: '',
            sets: 4,
            reps: '10-12',
            rest: '90s'),
        Exercise(
            name: '蝴蝶机反向飞鸟',
            muscles: ['肩'],
            muscleTarget: '后束',
            sets: 4,
            reps: '12-15',
            rest: '60s'),
        Exercise(
            name: '哑铃交替弯举',
            muscles: ['肱二头'],
            muscleTarget: '',
            sets: 4,
            reps: '10-12',
            rest: '60s'),
      ]),
  WorkoutTemplate(
      id: 'legs',
      name: '腿 · 核心与肩补强',
      note: '练后参考：拉伸后回家，不安排练后有氧。',
      exercises: [
        Exercise(
            name: '倒蹬机',
            muscles: ['臀腿'],
            muscleTarget: '',
            sets: 4,
            reps: '8-10',
            rest: '90s'),
        Exercise(
            name: '哑铃罗马尼亚硬拉',
            muscles: ['臀腿'],
            muscleTarget: '后链',
            sets: 4,
            reps: '10-12',
            rest: '90s'),
        Exercise(
            name: '坐姿腿屈伸',
            muscles: ['股四头'],
            muscleTarget: '',
            sets: 3,
            reps: '12-15',
            rest: '60s'),
        Exercise(
            name: '器械卷腹',
            muscles: ['腹肌'],
            muscleTarget: '',
            sets: 4,
            reps: '12-15',
            rest: '60s'),
        Exercise(
            name: '哑铃侧平举',
            muscles: ['肩'],
            muscleTarget: '中束补强',
            sets: 3,
            reps: '12-15',
            rest: '60s'),
      ]),
  WorkoutTemplate(id: 'cardio', name: '有氧与散步', note: '按当天体力选择即可。', exercises: [
    Exercise(
        name: '爬坡快走',
        muscles: ['有氧'],
        muscleTarget: '',
        sets: 1,
        reps: '20分钟',
        rest: '',
        note: '参考坡度 8–12，速度 4.5–5.0 km/h；不慢跑。'),
    Exercise(
        name: '晚饭后散步',
        muscles: ['恢复'],
        muscleTarget: '',
        sets: 1,
        reps: '30分钟',
        rest: '',
        note: '周末参考：全天 7000–8000 步。'),
  ]),
];

const defaultSchedule = ['push', 'pull', '', 'legs', '', '', ''];
const recoveryNotes = [
  '',
  '',
  '今天参考休息。若提前练腿，可自由加入腿模板，再调整周四安排。',
  '',
  '回老家恢复：不安排力量或跑步；晚饭后可散步 30 分钟，全天参考 7000–8000 步。',
  '回老家恢复：不安排力量或跑步；晚饭后可散步 30 分钟，全天参考 7000–8000 步。',
  '回老家恢复：不安排力量或跑步；晚饭后可散步 30 分钟，全天参考 7000–8000 步。',
];
