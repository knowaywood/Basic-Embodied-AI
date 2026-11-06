#import "../_symbols.typ": *

= 机器人学习

== 经典机器人

== 机器学习与深度学习基础
=== 强化学习简介
强化学习让机器人在与环境的交互中不断尝试: 每执行一个动作, 智能体都会得到一个数值奖励, 用来判断这一步是否有助于实现目标, 并据此调整策略. 这个过程不要求事先准确描述环境如何随动作变化.

#figure(image("/images/2-1 RL.png", width: 70%), caption: "智能体-环境交互图")
从形式上讲, 智能体与环境的交互通常用 #link("https://en.wikipedia.org/wiki/Markov_decision_process")[马尔可夫决策过程（Markov Decision Process, MDP）] 建模. 这里讨论离散时间、有限时域的 MDP, 其时域长度为 $T$, 可表示为元组 $cal(M) = chevron.l cal(S), cal(A), cal(D), r, gamma, rho, T chevron.r$, 其中:

- $cal(S)$ 是状态空间, $s_t in cal(S)$ 表示时刻 $t$ 的环境状态. 在机器人任务中, 状态通常包括机器人的配置和速度 $(q, dot(q))$, 也可以包含摄像头、麦克风等传感器的数据.

- $cal(A)$ 是动作空间, $a_t in cal(A)$ 表示时刻 $t$ 的动作, 例如关节扭矩、关节速度或末端执行器的控制指令.

- $cal(D)$ 是环境的状态转移模型, 描述在状态 $s_t$ 下执行动作 $a_t$ 后, 转移到状态 $s_(t+1)$ 的概率: $cal(D): cal(S) times cal(A) times cal(S) |-> [0, 1], quad cal(D)(s_t, a_t, s_(t+1)) = bb(P)(s_(t+1) | s_t, a_t)$. 以平面机械手为例, 如果相关因素都已知, 当前状态和动作就能确定下一状态; 如果存在不可观测的扰动, 同一状态和动作也可能产生不同的结果.

- $r: cal(S) times cal(A) times cal(S) -> RR$ 是奖励函数, 为智能体在状态 $s_t$ 下执行动作 $a_t$ 并到达 $s_(t+1)$ 的过程打分, 反映结果是否符合目标. 例如, 如果希望机器人沿 $x$ 轴快速移动, 可以根据它的位置 $p_(x_t)$ 和速度 $dot(p_(x_t))$ 给予奖励, 同时根据机身高度 $p_(z_t)$ 惩罚跌倒: $r(s_t, a_t, s_(t+1)) eq.triple r(s_t) = p_(x_t) dot dot(p_(x_t)) - 1 / p_(z_t)$. 下文记 $r_t = r(s_t, a_t, s_(t+1))$.

- $gamma in [0, 1)$ 是折现因子, 决定未来奖励在回报中占多大比重. 相隔 $k$ 步的奖励乘以 $gamma^k$: $gamma$ 越小, 智能体越看重眼前的奖励; 越接近 1, 越重视未来的奖励. $1 / (1 - gamma)$ 可粗略理解为考虑奖励的有效步数, 并不表示之后的奖励会被完全忽略.

- $rho$ 是初始状态的分布, 即 $s_0 ~ rho$.

长度为 $T$ 的轨迹 $tau$ 是一条由状态、动作和奖励组成的随机序列:

$
  tau = (s_0, a_0,r_0, s_1, a_1,r_1, ..., s_(T-1), a_(T-1),r_(T-1), s_T)
$

若环境满足#link("https://en.wikipedia.org/wiki/Markov_property")[马尔可夫性质], 即下一状态只取决于当前状态和动作, 且 *策略*#footnote[策略（policy, $pi$）是智能体选择动作的规则. 随机策略用 $pi(a | s)$ 表示在状态 $s$ 下选择动作 $a$ 的概率; 确定性策略可写为 $a = pi(s)$. ] 只根据当前状态选择动作, 则有:

$
  bb(P)(s_(t+1) | s_t, a_t , s_(t-1) ,a_(t-1), ..., s_0, a_0) = bb(P)(s_(t+1) | s_t, a_t)\
  bb(P)(a_(t)| s_(t), s_(t-1), a_(t-1), ..., s_0, a_0) = bb(P)(a_(t)| s_(t))
$

给定初始状态分布 $rho$ 和状态转移模型 $cal(D)$, 策略 $pi_theta$ 产生轨迹 $tau$ 的概率为:
$
  bb(P)_(theta, cal(D))(tau) = rho(s_0) product_(t=0)^(T-1) cal(D)(s_t, a_t, s_(t+1)) pi_theta (a_t | s_t)
$

轨迹的折现回报是沿途奖励按时间折现后的总和:
$
  G(tau) = sum_(t=0)^(T-1) gamma^t r_t
$

智能体要学习使期望回报最大的策略. 在给定环境中, 同一策略可能产生不同的轨迹; 对这些轨迹的回报取期望, 就得到该策略的期望回报. 由此可以比较策略空间 $Pi$ 中的策略, 并将优化目标写为:
$
  J: Pi -> RR, quad J(pi_theta) = bb(E)_(tau ~ bb(P)_(theta, cal(D))) [G(tau)]
$
MDP 为比较和优化策略提供了框架, 最优策略可写为 $pi^* = arg max_theta J(pi_theta)$. 其中, $theta$ 是策略参数, $Pi$ 是策略空间, 对任意 $theta$ 都有 $pi_theta in Pi$. 除了评价整条轨迹, 回报 $G(tau)$ 还可用于评价状态及状态—动作组合. 例如, 对于机器人某一配置 $q$ 所对应的状态 $s in cal(S)$, 可以定义状态价值函数:

$
  V_pi (s) = bb(E)_(tau ~ pi) [G(tau) | s_0 = s]
$
在给定策略 $pi$ 下, 状态价值函数表示从状态 $s$ 出发的预期回报, 可用于比较不同状态. 类似地, 状态—动作价值函数表示在状态 $s$ 下先选择动作 $a$ 、此后按照策略 $pi$ 行动时的预期回报:

$
  Q_pi (s, a) = bb(E)_(tau ~ pi) [G(tau) | s_0 = s, a_0 = a]
$
根据贝尔曼方程, 两个价值函数还满足:
$
  Q_pi (s_t, a_t) =
  bb(E)_(s_(t+1) ~ bb(P)(dot | s_t, a_t))
  [r_t + gamma V_pi (s_(t+1))]
  \
  V_pi (s_t) =
  bb(E)_(a_t ~ pi(dot | s_t))
  [Q_pi (s_t, a_t)]
$

价值函数使我们能够在给定策略 $pi$ 下, 比较不同状态和状态—动作组合的优劣. 许多强化学习算法据此改进策略.

== 高效率强化学习算法
最优策略 $pi^*$ 对应的状态—动作价值函数记为 $Q^* eq.triple Q_(pi^*)$. 在状态 $s_t$ 下, 最优动作 $mu(s_t)$ 是使 $Q^*(s_t,a_t)$ 最大的动作:

$
  mu(s_t) = argmax_(a_t in cal(A)) Q^* (s_t,a_t)
$

计算当前动作的价值 $Q^*(s_t,a_t)$ 时, 要考虑执行动作后的奖励 $r_t$, 以及可能到达的下一状态 $s_(t+1)$. 从下一状态起, 智能体继续选择价值最高的动作. 对可能的下一状态取期望, 就得到贝尔曼最优方程（Bellman optimality equation）:

$
  Q^* (s_t,a_t)=bb(E)_(s_(t+1) ~ bb(P)(dot | s_t, a_t)) [r_t + gamma max_(a_(t+1)in cal(A)) Q^* (s_(t+1),a_(t+1)) mid(|) s_t,a_t]
$

最优 $Q$ 函数按定义满足这一递归关系. 价值迭代方法利用贝尔曼方程, 反复更新对 $Q^*$ 的估计; $Q$ -learning 就是一例:

$
  Q_(i+1) (s_t,a_t) arrow.l bb(E)_(s_(t+1) ~ bb(P)(dot | s_t, a_t)) [r_t + gamma max_(a_(t+1)in cal(A)) Q_i (s_(t+1),a_(t+1)) mid(|) s_t,a_t], quad i = 0,1,2,...,K
$

普通 $Q$ -learning 在早期的小规模离散问题中效果良好, 但难以扩展到较大的 $cal(S) times cal(A)$ 空间: 单是存储 $Q: cal(S) times cal(A) -> RR$ 就可能代价过高. 此外, 它也不能直接用于状态—动作空间连续且缺乏明确结构的 MDP, 例如机器人领域的问题.

Mnih 等人（2013）提出深度 $Q$ 学习（Deep Q-Learning, DQN）, 用深度卷积神经网络学习 $Q$ 值, 以处理大规模甚至缺乏明确结构的状态空间. DQN 用参数为 $theta$ 的神经网络表示 $Q$ 函数, 通过逐步减小平方 TD 误差的期望来更新参数:

$
  L(theta_i) =& bb(E)_((s_t,a_t)~chi(dot)) [(y_i-Q_(theta_i) (s_t,a_t))^2]\
  y_i =& bb(E)_(s_(t+1)~bb(P)(dot | s_t, a_t)) [r_t + gamma max_(a_(t+1)in cal(A)) Q_(theta_(i-1)) (s_(t+1),a_(t+1))]
$ <td-target>

其中, $y_i$ 是用上一轮参数 $theta_(i-1)$ 计算的目标值; 它与当前预测值 $Q_(theta_i)(s_t,a_t)$ 之差 $delta_i$ 称为时序差分误差（TD 误差）. 训练时最小化其平方的期望 $L(theta_i)$. $chi$ 是训练数据中状态—动作对的分布, 可以不同于当前策略产生的数据分布. 先前交互得到的 $(s_t,a_t,r_t,s_(t+1))$ 可存入经验回放缓冲区 $D$, 供后续抽样训练.

对于离散动作问题, DQN 能处理大规模、缺乏明确结构的状态空间, 但难以直接用于连续控制. 若用神经网络近似 $Q$ 函数, 每一步都要求解 $max_(a_t in cal(A)) Q_theta (s_t,a_t)$. 由于动作空间连续（ $cal(A) subset.eq RR^n$）, 逐步求解这一最大值的代价很高, 也通常无法解析求解.

为此, Silver 等人（2014）采用由状态直接确定动作的策略 $mu_phi.alt (s_t) = a_t$, 其中 $phi.alt$ 是策略参数. 沿以下方向更新参数, 可以逐步改进策略:

$
  d_phi.alt =& bb(E)_(s_t ~ bb(P)(dot)) [nabla_phi.alt Q(s_t, a_t) mid(|)_(a_t = mu_phi.alt (s_t))]
  =& bb(E)_(s_t ~ bb(P)(dot)) [nabla_(a_t) Q(s_t, a_t) mid(|)_(a_t = mu_phi.alt (s_t)) dot nabla_phi.alt mu_phi.alt (s_t)]
$

这个方向 $d_phi.alt$ 称为确定性策略梯度（Deterministic Policy Gradient, DPG）. 按 $phi.alt_(k+1) = phi.alt_k + alpha d_phi.alt$ 更新参数, 可以提高确定性策略的期望回报 $J(mu_phi.alt)$.

Lillicrap 等人（2019）将 DPG 扩展到高维、缺乏明确结构的观测和连续动作空间, 提出深度确定性策略梯度（Deep Deterministic Policy Gradient, DDPG）. DDPG 使用策略网络选择动作, 并相应修改 TD 目标 @td-target :

$
  y_i = bb(E)_(s_(t+1)~bb(P)(dot | s_t, a_t)) [r_t + gamma Q_(theta_(i-1)) (s_(t+1),mu_phi.alt (s_(t+1)))]
$

与 DQN 类似, DDPG 也使用经验回放缓冲区, 重复利用先前的状态转移, 并通过采样估计损失函数.

软演员—评论家算法（Soft Actor-Critic, SAC）也用 $Q$ 函数评价动作, 用策略选择动作. 其策略给出动作的概率分布, 从而保留尝试不同动作的可能性. 最大熵强化学习（MaxEnt RL）用策略熵衡量这种随机性, 并将其加入优化目标; $alpha$ 控制熵项的权重:

$
  J(pi) = sum^(T)_(t=0) bb(E)_((s_t,a_t)~chi) [r_t + alpha cal(H)(pi(dot mid(|) s_t))]
$

这里的 $J(pi)$ 衡量策略 $pi$ 的整体表现, SAC 希望最大化各步奖励与熵奖励之和. $cal(H)(pi(dot mid(|) s_t))$ 是策略在状态 $s_t$ 下的熵, 衡量动作概率分布有多分散; 熵越大, 策略越不会只集中于少数动作.

训练 $Q$ 函数时, SAC 在下一状态按当前策略采样动作, 并把该动作的对数概率计入 TD 目标. 这样, $Q$ 值同时反映未来奖励和策略的随机性, 得到软 TD 目标:
$
  y_i = bb(E)_(s_(t+1)~bb(P)(dot | s_t,a_t)) [r_t + gamma (Q_(theta_(i-1))(s_(t+1),a_(t+1)) - alpha log pi_phi.alt (a_(t+1) | s_(t+1)))], quad a_(t+1) ~ pi_phi.alt (dot | s_(t+1))
$

更新策略时, SAC 希望价值较高的动作更容易被选到, 同时保留动作分布的随机性. 下面用 KL 散度衡量新策略与目标分布的差异, 并在策略空间 $Pi$ 中寻找差异最小的策略:
$
  pi_(k+1) <-  argmin_(pi' in Pi) D_("KL")(pi'(dot | s_t) mid(||) exp(Q_(pi_k) (s_t,dot)) / (Z_(pi_k) (s_t)))
$

其中, $D_("KL")(p mid(||) q)$ 是 KL 散度, 衡量分布 $p$ 相对于 $q$ 的差异. 对于连续动作空间, 归一化因子为:
$ Z_(pi_k)(s_t) = integral_(cal(A)) exp(Q_(pi_k)(s_t,a)) dif a$.
$exp(Q_(pi_k) (s_t,dot)) / (Z_(pi_k) (s_t))$ 是一个概率分布; $Pi$ 可以选为高斯分布等易于计算的分布族.


== 深度强化学习: PPO 与 SAC

== 模仿学习、离线 RL 与运动先验



== 具身强化学习与运动控制 RL

== 生成式策略: Flow Matching

== 通用运动控制: GROOOT 与 SONIC

== 参考文献
