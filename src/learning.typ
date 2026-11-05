#import "../_symbols.typ": *

= 机器人学习

== 经典机器人

== 机器学习与深度学习基础
=== 强化学习简介
强化学习让机器人在与环境的交互中不断尝试: 每做出一个动作, 它都会收到一个数值形式的奖励, 以了解这一步是否有助于实现目标, 并据此调整策略. 此过程不需要精确描述环境如何随动作变化.

#figure(image("/images/2-1 RL.png", width: 70%), caption: "智能体-环境交互图")
从形式上讲, 智能体与其环境之间的交互通常通过 #link("https://en.wikipedia.org/wiki/Markov_decision_process")[马尔可夫决策过程 (Markov Decision Process, MDP)] 来建模. 本文讨论的为离散时间、有限的马尔可夫决策过程. 长度为 $T$ 的马尔可夫决策过程是一个元组 $cal(M) = chevron.l cal(S), cal(A), cal(D), r, gamma, rho, T chevron.r$, 其中:

- $cal(S)$ 代表状态空间; $s_t in cal(S)$ 则表示在时间点 $t$ 时的环境状态. 在机器人技术中, 状态通常包括机器人的配置和速度信息 $(q, dot(q))$, 同时也可以包含来自传感器的数据, 比如摄像头或音频信号.

- $cal(A)$ 代表动作空间; $a_t in cal(A)$ 可以表示在时间点 $t$ 时的关节扭矩、关节速度, 或是末端执行器的控制指令. 一般来说, 这些动作都是对机器人结构进行控制的指令.

- $cal(D)$ 是环境的状态转移模型, 描述在状态 $s_t$ 下执行动作 $a_t$ 后, 环境转移到状态 $s_(t+1)$ 的概率: $cal(D): cal(S) times cal(A) times cal(S) |-> [0, 1], quad cal(D)(s_t, a_t, s_(t+1)) = bb(P)(s_(t+1) | s_t, a_t)$. 以平面机械手为例, 如果环境中的相关因素都已知, 给定当前状态和动作就能确定下一状态; 如果存在受不可观测因素影响的扰动, 相同的状态和动作也可能产生不同的结果.

- $r: cal(S) times cal(A) times cal(S) -> RR$ 是奖励函数, 为智能体在状态 $s_t$ 下采取动作 $a_t$ 并到达 $s_(t+1)$ 的这一步打分, 反映结果是否符合目标. 例如, 若希望机器人沿 $x$ 轴快速移动, 可以根据它在 $x$ 轴上的位置 $p_(x_t)$ 和速度 $dot(p_(x_t))$ 给予奖励, 同时用机身高度 $p_(z_t)$ 对跌倒进行惩罚: $r(s_t, a_t, s_(t+1)) eq.triple r(s_t) = p_(x_t) dot dot(p_(x_t)) - 1 / p_(z_t)$. *我们定义 $r_t = r(s_t, a_t, s_(t+1))$. *

- $gamma in [0, 1)$ 是折现因子, 决定智能体有多重视未来的奖励. 距离当前 $k$ 步后获得的奖励 $r_k$ 会乘以 $gamma^k$: $gamma$ 越小, 智能体越看重眼前的奖励; $gamma$ 越接近 1, 越重视长远的收益. $1 / (1 - gamma)$ 可粗略理解为智能体考虑奖励的有效步数, 并不表示超过这个步数的奖励会被完全忽略.

- $rho$ 是初始状态 $S$ 的分布, 描述一轮交互开始时状态 $s_0$ 的分布, 即 $s_0 ~ rho$.

长度为 $T$ 的轨迹实际上是这样的（随机）序列:

$
  tau = (s_0, a_0,r_0, s_1, a_1,r_1, ..., s_(T-1), a_(T-1),r_(T-1), s_T)
$

若环境满足#link("https://en.wikipedia.org/wiki/Markov_property")[马尔可夫性质], 即下一状态只取决于当前状态和动作, 并且 *策略*#footnote[策略 (policy, $pi$)  是智能体的决策规则: 它规定智能体在状态 $s$ 下如何选择动作 $a$. 对于随机策略, $pi(a | s)$ 表示在状态 $s$ 下选择动作 $a$ 的概率; 对于确定性策略, 可写为 $a = pi(s)$.] 只根据当前状态选择动作, 则有:

$
  bb(P)(s_(t+1) | s_t, a_t , s_(t-1) ,a_(t-1), ..., s_0, a_0) = bb(P)(s_(t+1) | s_t, a_t)\
  bb(P)(a_(t)| s_(t), s_(t-1), a_(t-1), ..., s_0, a_0) = bb(P)(a_(t)| s_(t))
$

在初始状态分布 $rho$ 和环境动力学 $cal(D)$ 给定的情况下, 策略 $pi_theta$ 产生轨迹 $tau$ 的概率为:
$
  bb(P)_(theta, cal(D))(tau) = rho(s_0) product_(t=0)^(T-1) cal(D)(s_t, a_t, s_(t+1)) pi_theta (a_t | s_t)
$

一条轨迹的折现回报, 是沿途奖励按时间折现后的总和:
$
  G(tau) = sum_(t=0)^(T-1) gamma^t r_t
$

智能体要学习的是使期望回报最大的 *控制策略* . 在给定的环境(任务)中, 同一策略可能产生不同的轨迹; 将各条可能轨迹的回报按分布求期望, 就得到该策略的期望回报. 这样便可以按照任务目标比较策略空间 $Pi$ 中策略的优劣, 并将优化目标写为:
$
  J: Pi -> RR, quad J(pi_theta) = bb(E)_(tau ~ bb(P)_(theta, cal(D))) [G(tau)]\
  "其中" bb(P)_(theta;cal(D)) (tau) = rho product_(t=1)^(T-1) cal(D)(s_t,a_(t-1),s_(t-1)) pi_theta (a_t|s_t)
$
MDP 提供了一个框架, 可以用来优化智能体可能采取的各种行为, 从而找到最优的策略 $pi^* = arg max_theta J(pi_theta)$. 其中, $theta$ 是策略的参数, 策略空间 $Pi$ 包含由这些参数表示的策略, 即对任意 $theta$, 都有 $pi_theta in Pi$. $G(t)$ 还可以用来区分不同的状态 $s_t$ 和 $(s_t,a_t)$. 给定任何一个状态 $s in cal(S)$, 例如, 给定机器人的某个配置 $q$, 就可以利用状态价值函数来进行分析.

$
  V_pi (s) = bb(E)_(tau ~ pi) [G(tau) | s_0 = s]
$
它可用于根据长期最大化目标奖励, 来区分什么是理想状态, 什么是非理想状态. 类似地, 状态—动作价值函数表示: 在状态 $s$ 下选择动作 $a$, 且按照策略 $pi$ 行动时, 预期能累计获得多少奖励.

$
  Q_pi (s, a) = bb(E)_(tau ~ pi) [G(tau) | s_0 = s, a_0 = a]
$
变形后:
$
  Q_pi (s_t, a_t) =
  bb(E)_(s_(t+1) ~ bb(P)(dot | s_t, a_t))
  [r_t + gamma V_pi (s_(t+1))]
  \
  V_pi (s_t) =
  bb(E)_(a_t ~ pi(dot | s_t))
  [Q_pi (s_t, a_t)]
$

值函数使我们能够在给定策略 $pi$ 下, 比较不同状态以及不同"状态—动作"组合的优劣. 许多强化学习算法正是依据这种比较来改进策略.

== 高效率强化学习算法
在马尔可夫决策过程（MDP）中, 最优策略 $pi^*$ 对应的动作价值函数记为 $Q^* eq.triple Q_(pi^*)$. 在状态 $s_t$ 下, 选择使 $Q^*(s_t,a_t)$ 最大的动作, 就得到最优策略所采取的动作 $mu(s_t)$:

$
  mu(s_t) = argmax_(a_t in cal(A)) Q^* (s_t,a_t)
$

而要确定当前动作的价值 $Q^*(s_t,a_t)$, 还需考虑执行动作后获得的奖励 $r_t$, 以及可能到达的下一状态 $s_(t+1)$. 从下一状态起, 智能体仍选择价值最高的动作. 对所有可能的下一状态取期望, 便得到 $Q^*$ 满足的递归关系, 即贝尔曼最优方程（Bellman optimality equation）:

$
  Q^* (s_t,a_t)=bb(E)_(s_(t+1) ~ bb(P)(dot | s_t, a_t)) [r_t + gamma max_(a_(t+1)in cal(A)) Q^* (s_(t+1),a_(t+1)) mid(|) s_t,a_t]
$

最优 $Q$ 函数按定义满足这一递归关系. 价值迭代方法利用贝尔曼方程, 反复更新对 $Q^*$ 的估计 $Q_h$; 如 $Q$ -learning:

$
  Q_(i+1) (s_t,a_t) arrow.l bb(E)_(s_(t+1) ~ bb(P)(dot | s_t, a_t)) [r_t + gamma max_(a_(t+1)in cal(A)) Q_i (s_(t+1),a_(t+1)) mid(|) s_t,a_t], quad i = 0,1,2,...,K
$

普通 $Q$ -learning 在早期的小规模离散问题中效果良好, 但难以扩展到较大的 $cal(S) times cal(A)$ 空间: 单是存储 $Q: cal(S) times cal(A) -> RR$ 就可能难以承受. 此外, 它也不能直接用于状态—动作空间连续且无结构的 MDP, 机器人领域中的问题便是如此. Mnih 等人（2013）在深度 $Q$ 学习（Deep Q-Learning, DQN）的工作中, 提出用深度卷积神经网络学习 $Q$ 值, 从而处理大规模甚至无结构的状态空间. DQN 用参数为 $theta$ 的神经网络表示 $Q$ 函数, 并通过逐步最小化期望平方时序差分误差来更新参数:

$
  L(theta_i) =& bb(E)_((s_t,a_t)~chi(dot)) [(y_i-Q_(theta_i) (s_t,a_t))^2]\
  y_i =& bb(E)_(s_(t+1)~bb(P)(dot | s_t, a_t)) [r_t + gamma max_(a_(t+1)in cal(A)) Q_(theta_(i-1)) (s_(t+1),a_(t+1))]
$

其中, $y_i$ 是用上一轮参数 $theta_(i-1)$ 计算的目标值; 它与当前预测值 $Q_(theta_i)(s_t,a_t)$ 之差 $delta_i$ 称为时序差分误差（TD 误差）. 训练时最小化其平方的期望 $L(theta_i)$.

$chi$ 是训练数据中状态—动作对的分布, 可以不同于当前策略产生的数据分布. 先前交互得到的 $(s_t,a_t,r_t,s_(t+1))$ 可存入经验回放缓冲区 $D$, 供后续抽样训练.

对于离散动作问题, DQN 能够处理大规模、无结构的状态空间, 但将其用于连续控制并不容易. 若用神经网络等复杂函数来近似 $Q$ 函数, 每一步都要求解 $max_(a_t in cal(A)) Q_theta(s_t,a_t)$. 由于动作空间连续（ $cal(A) subset.eq RR^n$）, 且难以找到计算代价较低、最好具有闭式解的策略来解析地求出这一最大值, 逐步求解便不可行. 为此, Silver 等人（2014）采用由状态直接确定动作的策略 $mu_phi(s_t) = a_t$, 其中 $phi$ 为策略参数; 通过迭代更新 $phi$, 可以逐步改进策略:

$
  d_phi =& bb(E)_(s_t ~ bb(P)(dot)) [nabla_phi Q(s_t, a_t) |_(a_t = mu_phi(s_t))] \
        =& bb(E)_(s_t ~ bb(P)(dot)) [nabla_(a_t) Q(s_t, a_t) |_(a_t = mu_phi(s_t)) dot nabla_phi mu_phi(s_t)]
$

这个方向 $d_phi$ 称为确定性策略梯度（Deterministic Policy Gradient, DPG）. 按 $phi_(k+1) = phi_k + alpha d_phi$ 更新策略参数, 可以提高确定性策略的期望回报 $J(mu_phi)$. Lillicrap 等人（2019）将 DPG 扩展到高维、无结构的观测和连续动作空间, 提出深度确定性策略梯度（Deep Deterministic Policy Gradient, DDPG）. DDPG 使用策略网络选择动作, 并据此修改时序差分目标.



与 DQN 类似, DDPG 也采用了相同的重放缓冲机制, 通过重复利用训练过程中的状态转移来提升样本处理的效率, 并通过蒙特卡洛估计法来估算损失函数.

== 强化学习基础: MDP、价值函数与策略梯度

== 深度强化学习: PPO 与 SAC

== 模仿学习、离线 RL 与运动先验

== 具身强化学习与运动控制 RL

== 生成式策略: Flow Matching

== 通用运动控制: GROOOT 与 SONIC

== 参考文献
