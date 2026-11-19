import '../models/daily_workout.dart';
import '../models/recomp_models.dart';

// Fixed daily reference routines Mon-Sun; every day can be customized or set to Rest.
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
  WorkoutTemplate(
      id: 'core_cardio',
      name: '核心 · 代谢有氧',
      note: '周中主动代谢训练日：强化腹横肌与心肺恢复。',
      exercises: [
        Exercise(
            name: '器械卷腹',
            muscles: ['核心'],
            muscleTarget: '腹直肌',
            sets: 4,
            reps: '12-15',
            rest: '60s'),
        Exercise(
            name: '平板支撑',
            muscles: ['核心'],
            muscleTarget: '深层核心',
            sets: 3,
            reps: '45秒',
            rest: '60s'),
        Exercise(
            name: '仰卧举腿',
            muscles: ['核心'],
            muscleTarget: '下腹肌',
            sets: 3,
            reps: '12-15',
            rest: '60s'),
        Exercise(
            name: '爬坡快走',
            muscles: ['有氧恢复'],
            muscleTarget: '低冲击燃脂',
            sets: 1,
            reps: '20分钟',
            rest: ''),
      ]),
  WorkoutTemplate(
      id: 'upper_pump',
      name: '上肢 · 泵感与手臂',
      note: '聚焦上胸、背宽与手臂围度塑造，中等重量保持高质量收缩。',
      exercises: [
        Exercise(
            name: '上斜哑铃卧推',
            muscles: ['胸部'],
            muscleTarget: '上胸',
            sets: 3,
            reps: '10-12',
            rest: '90s'),
        Exercise(
            name: '单臂哑铃划船',
            muscles: ['背部'],
            muscleTarget: '背阔肌',
            sets: 3,
            reps: '10-12',
            rest: '90s'),
        Exercise(
            name: '绳索侧平举',
            muscles: ['肩部'],
            muscleTarget: '中束',
            sets: 4,
            reps: '12-15',
            rest: '60s'),
        Exercise(
            name: '哑铃锤式弯举',
            muscles: ['手臂'],
            muscleTarget: '肱二头 / 肱肌',
            sets: 3,
            reps: '12-15',
            rest: '60s'),
        Exercise(
            name: '绳索过顶臂屈伸',
            muscles: ['手臂'],
            muscleTarget: '肱三头长头',
            sets: 3,
            reps: '12-15',
            rest: '60s'),
      ]),
  WorkoutTemplate(
      id: 'recovery',
      name: '拉伸与主动恢复',
      note: '周日轻松激活与放松：不堆高强度负荷，为下一周蓄力。',
      exercises: [
        Exercise(
            name: '死虫式',
            muscles: ['核心'],
            muscleTarget: '核心激活',
            sets: 2,
            reps: '10-12',
            rest: '45s'),
        Exercise(
            name: '拉伸放松',
            muscles: ['有氧恢复'],
            muscleTarget: '胸肩髋柔韧',
            sets: 1,
            reps: '20分钟',
            rest: ''),
        Exercise(
            name: '晚饭后散步',
            muscles: ['有氧恢复'],
            muscleTarget: '日常活动',
            sets: 1,
            reps: '30分钟',
            rest: ''),
      ]),
];

// Monday..Sunday default fixed daily templates.
const defaultSchedule = [
  'push',
  'pull',
  'core_cardio',
  'legs',
  'upper_pump',
  'cardio',
  'recovery',
];

const recoveryNotes = [
  '',
  '',
  '周中主动恢复日，可根据状态切换为休息或核心代谢训练。',
  '',
  '周末轻度恢复：保持日常步数 7000–8000 步与拉伸。',
  '周末轻度恢复：保持日常步数 7000–8000 步与拉伸。',
  '周末主动恢复：拉伸放松并散步，为下周训练周期做好准备。',
];
