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
  J: Pi -> RR, quad J(pi_theta) = EE_(tau ~ bb(P)_(theta, cal(D))) [G(tau)]
$
MDP 为比较和优化策略提供了框架, 最优策略可写为 $pi^* = arg max_theta J(pi_theta)$. 其中, $theta$ 是策略参数, $Pi$ 是策略空间, 对任意 $theta$ 都有 $pi_theta in Pi$. 除了评价整条轨迹, 回报 $G(tau)$ 还可用于评价状态及状态—动作组合. 例如, 对于机器人某一配置 $q$ 所对应的状态 $s in cal(S)$, 可以定义状态价值函数:

$
  V_pi (s) = EE_(tau ~ pi) [G(tau) | s_0 = s]
$
在给定策略 $pi$ 下, 状态价值函数表示从状态 $s$ 出发的预期回报, 可用于比较不同状态. 类似地, 状态—动作价值函数表示在状态 $s$ 下先选择动作 $a$ 、此后按照策略 $pi$ 行动时的预期回报:

$
  Q_pi (s, a) = EE_(tau ~ pi) [G(tau) | s_0 = s, a_0 = a]
$
根据贝尔曼方程, 两个价值函数还满足:
$
  Q_pi (s_t, a_t) =
  EE_(s_(t+1) ~ bb(P)(dot | s_t, a_t))
  [r_t + gamma V_pi (s_(t+1))]
  \
  V_pi (s_t) =
  EE_(a_t ~ pi(dot | s_t))
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
  Q^* (s_t,a_t)=EE_(s_(t+1) ~ bb(P)(dot | s_t, a_t)) [r_t + gamma max_(a_(t+1)in cal(A)) Q^* (s_(t+1),a_(t+1)) mid(|) s_t,a_t]
$

最优 $Q$ 函数按定义满足这一递归关系. 价值迭代方法利用贝尔曼方程, 反复更新对 $Q^*$ 的估计; $Q$ -learning 就是一例:

$
  Q_(i+1) (s_t,a_t) arrow.l EE_(s_(t+1) ~ bb(P)(dot | s_t, a_t)) [r_t + gamma max_(a_(t+1)in cal(A)) Q_i (s_(t+1),a_(t+1)) mid(|) s_t,a_t], quad i = 0,1,2,...,K
$

普通 $Q$ -learning 在早期的小规模离散问题中效果良好, 但难以扩展到较大的 $cal(S) times cal(A)$ 空间: 单是存储 $Q: cal(S) times cal(A) -> RR$ 就可能代价过高. 此外, 它也不能直接用于状态—动作空间连续且缺乏明确结构的 MDP, 例如机器人领域的问题.

Mnih 等人（2013）提出深度 $Q$ 学习（Deep Q-Learning, DQN）, 用深度卷积神经网络学习 $Q$ 值, 以处理大规模甚至缺乏明确结构的状态空间. DQN 用参数为 $theta$ 的神经网络表示 $Q$ 函数, 通过逐步减小平方 TD 误差的期望来更新参数:

$
  L(theta_i) =& EE_((s_t,a_t)~chi(dot)) [(y_i-Q_(theta_i) (s_t,a_t))^2]\
  y_i =& EE_(s_(t+1)~bb(P)(dot | s_t, a_t)) [r_t + gamma max_(a_(t+1)in cal(A)) Q_(theta_(i-1)) (s_(t+1),a_(t+1))]
$ <td-target>

其中, $y_i$ 是用上一轮参数 $theta_(i-1)$ 计算的目标值; 它与当前预测值 $Q_(theta_i)(s_t,a_t)$ 之差 $delta_i$ 称为时序差分误差（TD 误差）. 训练时最小化其平方的期望 $L(theta_i)$. $chi$ 是训练数据中状态—动作对的分布, 可以不同于当前策略产生的数据分布. 先前交互得到的 $(s_t,a_t,r_t,s_(t+1))$ 可存入经验回放缓冲区 $D$, 供后续抽样训练.

对于离散动作问题, DQN 能处理大规模、缺乏明确结构的状态空间, 但难以直接用于连续控制. 若用神经网络近似 $Q$ 函数, 每一步都要求解 $max_(a_t in cal(A)) Q_theta (s_t,a_t)$. 由于动作空间连续（ $cal(A) subset.eq RR^n$）, 逐步求解这一最大值的代价很高, 也通常无法解析求解.

为此, Silver 等人（2014）采用由状态直接确定动作的策略 $mu_phi.alt (s_t) = a_t$, 其中 $phi.alt$ 是策略参数. 沿以下方向更新参数, 可以逐步改进策略:

$
  d_phi.alt =& EE_(s_t ~ bb(P)(dot)) [nabla_phi.alt Q(s_t, a_t) mid(|)_(a_t = mu_phi.alt (s_t))]
  =& EE_(s_t ~ bb(P)(dot)) [nabla_(a_t) Q(s_t, a_t) mid(|)_(a_t = mu_phi.alt (s_t)) dot nabla_phi.alt mu_phi.alt (s_t)]
$

这个方向 $d_phi.alt$ 称为确定性策略梯度（Deterministic Policy Gradient, DPG）. 按 $phi.alt_(k+1) = phi.alt_k + alpha d_phi.alt$ 更新参数, 可以提高确定性策略的期望回报 $J(mu_phi.alt)$.

Lillicrap 等人（2019）将 DPG 扩展到高维、缺乏明确结构的观测和连续动作空间, 提出深度确定性策略梯度（Deep Deterministic Policy Gradient, DDPG）. DDPG 使用策略网络选择动作, 并相应修改 TD 目标 @td-target :

$
  y_i = EE_(s_(t+1)~bb(P)(dot | s_t, a_t)) [r_t + gamma Q_(theta_(i-1)) (s_(t+1),mu_phi.alt (s_(t+1)))]
$

与 DQN 类似, DDPG 也使用经验回放缓冲区, 重复利用先前的状态转移, 并通过采样估计损失函数.

软演员—评论家算法（Soft Actor-Critic, SAC）也用 $Q$ 函数评价动作, 用策略选择动作. 其策略给出动作的概率分布, 从而保留尝试不同动作的可能性. 最大熵强化学习（MaxEnt RL）用策略熵衡量这种随机性, 并将其加入优化目标; $alpha$ 控制熵项的权重:

$
  J(pi) = sum^(T)_(t=0) EE_((s_t,a_t)~chi) [r_t + alpha cal(H)(pi(dot mid(|) s_t))]
$

这里的 $J(pi)$ 衡量策略 $pi$ 的整体表现, SAC 希望最大化各步奖励与熵奖励之和. $cal(H)(pi(dot mid(|) s_t))$ 是策略在状态 $s_t$ 下的熵, 衡量动作概率分布有多分散; 熵越大, 策略越不会只集中于少数动作.

训练 $Q$ 函数时, SAC 在下一状态按当前策略采样动作, 并把该动作的对数概率计入 TD 目标. 这样, $Q$ 值同时反映未来奖励和策略的随机性, 得到软 TD 目标:
$
  y_i = EE_(s_(t+1)~bb(P)(dot | s_t,a_t)) [r_t + gamma (Q_(theta_(i-1))(s_(t+1),a_(t+1)) - alpha log pi_phi.alt (a_(t+1) | s_(t+1)))], quad a_(t+1) ~ pi_phi.alt (dot | s_(t+1))
$

更新策略时, SAC 希望价值较高的动作更容易被选到, 同时保留动作分布的随机性. 下面用 KL 散度衡量新策略与目标分布的差异, 并在策略空间 $Pi$ 中寻找差异最小的策略:
$
  pi_(k+1) <- argmin_(pi' in Pi) D_("KL")(pi'(dot | s_t) mid(||) exp(Q_(pi_k) (s_t,dot)) / (Z_(pi_k) (s_t)))
$

其中, $D_("KL")(p mid(||) q)$ 是 KL 散度, 衡量分布 $p$ 相对于 $q$ 的差异. 对于连续动作空间, 归一化因子为:
$Z_(pi_k)(s_t) = integral_(cal(A)) exp(Q_(pi_k)(s_t,a)) dif a$.
$exp(Q_(pi_k) (s_t,dot)) / (Z_(pi_k) (s_t))$ 是一个概率分布; $Pi$ 可以选为高斯分布等易于计算的分布族.


== 深度强化学习: PPO 与 SAC

== 模仿学习、离线 RL 与运动先验
=== 行为克隆

在真实机器人上训练强化学习算法时, 在线探索成本较高, 也可能带来安全风险. 奖励函数需要针对任务设计, 判断任务是否成功有时还依赖额外设备, 训练过程也需要可靠地重置环境. 模仿学习则利用事先收集的专家示范学习控制策略: 示范中包含了任务目标和行为偏好, 因而可以减少早期探索, 也无需为这些示范单独设计奖励函数.

记专家轨迹的集合为 $cal(D) = {tau^((i))}^N_(i=1)$, 其中 $tau^((i)) = {(o^((i))_t,a_t^((i)))}^(T_i)_(t=0)$ 是第 $i$ 条轨迹. $o_t in cal(O)$ 表示观测, 例如图像或本体感知数据; $a_t in cal(A)$ 表示动作, 例如机器人的控制指令. 这些观测—动作对不包含奖励信息.

行为克隆（Behavioral Cloning, BC）学习从观测到动作的映射, 用来预测专家在相同观测下会采取的动作. Pomerleau（1988）提出的方法可以视为监督学习: 学习确定性映射 $f: cal(O) -> cal(A)$, 用 $f(o_t)$ 预测动作 $a_t$. 训练目标为:

$
  min_f EE_((o_t,a_t) ~ p(dot)) L(a_t, f(o_t))
$

其中, $(o_t,a_t)$ 是示范中的观测—动作对, $p$ 是其数据分布; $L: cal(A) times cal(A) -> RR$ 衡量预测动作 $f(o_t)$ 与示范动作 $a_t$ 的差异.

=== 生成式模型
生成式模型（Generative Models, GMs）尝试学习数据的生成过程, 通常用参数化的概率分布近似未知的数据分布 $p$. 在行为克隆中, $p(o,a)$ 可以表示专家观测与动作的联合分布.

从专家轨迹中取出 $N$ 个观测—动作对, 记为 $cal(D)_("BC") = {(o,a)_i}_(i=1)^N$, 并假设这些样本独立同分布. 生成式模型学习 $p_theta (o,a)$, 使它更倾向于生成专家示范中常见的 观测—动作 组合. 训练时, 模型会提高示范数据在这一分布下的概率, 从而逐步逼近专家数据的分布.


==== 变分自编码器(Variational Autoencoder, VAE)

变分自编码器（VAE）学习专家示范中观测—动作对 $(o,a)$ 的分布, 使模型能够生成与示范相似的样本. 这里生成的是整个 $(o,a)$ 对; 如果要根据当前观测 $o$ 直接选择动作 $a$, 还需要进一步构造以 $o$ 为条件的策略.

VAE 假设样本的生成受到不可观测的潜在变量 $z in Z$ 影响. 给定 $z$ 时, $p(o,a | z)$ 描述可能出现的观测—动作对; 不知道 $z$ 时, 则要考虑所有可能的 $z$:

$
  p(o,a) = integral_("supp"(Z)) p(o,a | z) p(z)
$

在机器人任务中, $z$ 可以表示示范者所执行任务的某些高层特征. 这是潜在变量的一种可能解释, 并不要求 $z$ 必须对应某个具体任务. 上式对 $z$ 积分, 得到整体的样本分布 $p(o,a)$.


为了使模型生成的样本接近示范, 希望提高示范样本在模型下的概率. 对前述由 $N$ 个独立同分布观测—动作对组成的数据集 $cal(D)_("BC")$, 其对数概率可写为:

$
  log p_theta (cal(D)_("BC"))
  &= log product_(i=1)^N p_theta ((o,a)_i) \
  &= sum_(i=1)^N log integral_("supp"(Z)) p_theta ((o,a)_i mid(|) z) p(z)\
  &= sum_(i=1)^N log integral_("supp"(Z)) (q_theta (z mid(|) (o,a)_i)) / (q_theta (z mid(|) (o,a)_i)) dot p_theta ((o,a)_i mid(|) z) p(z) \
  &= sum_(i=1)^N log EE_(z ~ q_theta (dot mid(|) (o,a)_i)) [p_theta ((o,a)_i mid(|) z) p(z) / (q_theta (z mid(|) (o,a)_i))]
$ <evidence-definition>

这里的 $q_theta (z | (o,a)_i)$ 是推导时引入的辅助分布. 乘以 $(q_theta (z mid(|) (o,a)_i)) / (q_theta (z mid(|) (o,a)_i)) = 1$ 后, 积分便可改写为关于 $q_theta$ 的期望; 这一步只是换了一种写法.

要真正计算 $p_theta (o,a)$, 仍需考虑所有可能的 $z$. 用神经网络表示高维数据分布时, 这一计算通常难以完成, 因而不便直接最大化上述对数概率.

VAE 因此引入参数为 $phi.alt$ 的推断模型 $q_phi.alt (z mid(|) o,a)$, 根据样本推测可能的 $z$; 参数为 $theta$ 的生成模型 $p_theta (o,a mid(|) z)$ 则根据 $z$ 生成样本. 两个模型共同训练, 使推断出的 $z$ 有助于还原示范.

为了得到可以训练的目标, 根据琴生不等式 $log EE [dot] >= EE [log(dot)]$, 可由 @evidence-definition 得到对数概率的下界:
$
  log p_theta (cal(D)_("BC")) >=& sum_(i=1)^N (EE_(z ~ q_theta (dot | (o,a)_i)) [log p_theta ((o,a)_i | z)] + EE_(z ~ q_theta (dot | (o,a)_i)) [log (p(z)/(q_theta (z|(o,a)_i)))])\
  =& sum_(i=1)^N (EE_( z~q_theta (dot|(o,a)_i))[log p_theta ((o,a)_i|z) ] -D_"KL" [q_theta (z|(o,a)_i) mid(||) p(z) ] )
$
其中, $D_"KL" (P || Q)$ 是 KL 散度（Kullback-Leibler Divergence）, 用来衡量两个分布的差异. 上式中的这一项比较辅助分布 $q_theta$ 与先验分布 $p(z)$.

从样本推测 $z$ 所需的后验分布为 $p_theta (z | o,a) = (p_theta (o,a | z) p(z)) / (p_theta (o,a))$. 由于分母难以计算, VAE 用可计算的 $q_phi.alt (z | o,a)$ 近似这个后验, 并把它用于上述下界, 得到训练目标——证据下界（Evidence Lower Bound, ELBO）:
$
  "ELBO"_(cal(D)_("BC")) (theta, phi.alt) = sum_(i=1)^N (EE_( z~q_phi.alt (dot|(o,a)_i))[log p_theta ((o,a)_i|z) ] -D_"KL" [q_phi.alt (z|(o,a)_i) mid(||) p(z) ] )
$

具体实现时, 将 $q_phi.alt (z | o,a)$ 设为高斯分布 $cal(N)(mu_phi.alt (o,a), Sigma_phi.alt (o,a))$ #footnote[ $mu$ 表示高斯分布的均值, $Sigma$ 表示协方差矩阵. 此处的 $mu_phi.alt (o,a)$ 、 $Sigma_phi.alt (o,a)$ 描述潜在变量 $z$ 的分布; 后文的 $mu_theta (z)$ 描述观测—动作对的生成分布, 其各向同性协方差写作 $sigma^2 I$.]. 推断网络输出它的均值和协方差, 因而可以从中采样 $z$. 两个网络的输入和输出如下:
#figure(
  table(
    columns: (auto, auto, auto, auto),
    inset: (x: 6pt, y: 5pt),
    stroke: 0.6pt,
    table.header([网络], [输入], [输出], [输出的用途]),
    [推断网络 $phi.alt$],
    [示范样本 $(o,a)$],
    [ $mu_phi.alt (o,a)$ 、 $Sigma_phi.alt (o,a)$],
    [确定高斯分布 $q_phi.alt (z | o,a)$, 并从中采样 $z$],

    [生成网络 $theta$],
    [潜在变量 $z$],
    [观测—动作对的预测均值 $mu_theta (z)$],
    [在下文的固定方差高斯例子中, 以该均值确定 $p_theta (o,a | z)$],
  ),
)

训练时, 样本依次经过推断、采样和生成三个步骤:

$
  (o,a) stretch(->)^("推断网络" phi.alt) q_phi.alt (z | o, a) stretch(->)^"采样" z stretch(->)^("生成网络" theta) p_theta (o, a | z)
$

ELBO 的第一项衡量生成模型能否根据 $z$ 还原示范样本; 第二项约束 $q_phi.alt (z | o,a)$ 不要过度偏离先验分布 $p(z)$. 这里选择标准高斯 $p(z) = cal(N)(0,I)$ 作为先验, 使两个高斯分布之间的 KL 散度便于计算. 这是建模选择, 不是从示范数据中推导出的结论.

#remark(title: [蒙特卡洛估计])[
  蒙特卡洛估计用随机抽取的样本平均值近似难以直接计算的期望. 对给定的观测—动作对 $(o,a)$, 从 $q_phi.alt (z | o,a)$ 中抽取 $K$ 个样本 $z_1, dots, z_K$, 则 ELBO 中的重建项可估计为:

  $
    EE_(z ~ q_phi.alt (dot | o,a)) [log p_theta (o,a | z)] approx 1/K sum_(k=1)^K log p_theta (o,a | z_k)
  $

  若将这一项写成需要最小化的重建损失, 其估计值应取负号.
]

将最大化 ELBO 改写为最小化损失, 可得到重建损失与正则项之和:

$
  min_(theta, phi.alt) - "ELBO"_((o,a)~cal(D)_("BC")) (theta, phi.alt) =& min_(theta, phi.alt) bold(L)^"rec" (theta) + bold(L)^"reg" (phi.alt)\
  bold(L)^"rec" (theta)=&-EE_( z~q_phi.alt (dot|(o,a)_i))[log p_theta ((o,a)_i|z) ] \
  bold(L)^"reg" (phi.alt)=&D_"KL" [q_phi.alt (z|(o,a)_i) mid(||) p(z) ]
$
训练时同时更新 $theta$ 和 $phi.alt$: 重建项通过采样得到的 $z$ 调整两个网络, 使生成结果接近示范样本; 正则项进一步约束推断网络给出的潜在变量分布.

与上面的蒙特卡洛估计相同, 将重建项写为损失后, 其采样近似带有负号:
$
  -EE_( z~q_phi.alt (dot|o,a))[log p_theta (o,a|z) ] =bold(L)^"rec" approx - 1/n sum_(k=1)^n log p_theta (o,a|z_k)
$

如果将 $p_theta (o, a|z)$ 设为均值为 $mu_theta (z) in RR^d$ 、方差为 $sigma^2$ 的各向同性高斯分布, 重建损失就与生成结果和示范样本之间的平方误差有关:

$
  log p_theta (o,a|z_k) & = -1/(2sigma^2) norm((o,a)-mu_theta (z_k))^2_2 - d/2 log(2pi sigma^2) \
          bold(L)^"rec" & approx 1/(2sigma^2 n) sum_(k=1)^n norm((o,a)-mu_theta (z_k))^2_2 + d/2 log(2pi sigma^2)
$

训练完成后, 可以从先验 $p(z)$ 采样, 再通过生成模型得到新的观测—动作对. 推断模型 $q_phi.alt (z | o, a)$ 则用于训练时从示范样本推测 $z$; 它不负责生成样本.


==== 扩散模型(Diffusion Model, DM)

VAE 用单个潜在变量 $z$ 近似未知的观测—动作对分布 $p(o,a)$, 并通过变分推断共同学习生成分布 $p_theta (o, a | z)$ 和近似后验 $q_phi.alt (z | o, a)$. 生成时, 先从 $p(z)$ 采样, 再由生成模型得到观测—动作对. 扩散模型（Diffusion Model, DM）同样要近似未知的数据分布, 但将 VAE 的单潜在变量模型扩展为多个相互影响的潜在变量. 它假设生成过程可以分解为一系列满足马尔可夫性质的转换. 记 $z_0 equiv (o,a)$, 其余潜在变量为 $z_1, dots, z_T$, 则对这些潜在变量积分, 可得

$
  p(o,a) = integral_("supp"(Z_1)) dots integral_("supp"(Z_T)) p(z_0,z_1,dots,z_T)
$

根据条件概率与马尔可夫性质, 联合分布可分解为

$
  p(z_0,z_1,dots,z_T) = p(z_T) product_(t=1)^T p(z_(t-1) | z_t).
$

与 VAE 类似, 这些潜在变量通常难以赋予确切含义. 不过, 分层马尔可夫潜在变量模型（Hierarchical Markov Latent Variable, HMLV）通过变量之间分层、相对独立的联系, 可以反映不同因素在不同尺度上的作用. 例如在机器人任务中, 接近 $z_T$ 的较高层级可以对应轨迹规划, 接近实际观测 $z_0$ 的层级则可以对应细致的运动调整. 因此, HMLV 可以通过多个层级上的依次采样来描述生成过程.

#figure(
  image("../images/2-2 manyLatents.png", width: 70%),
  caption: [HMLV 用一系列满足马尔可夫性质的潜在变量表示数据生成过程. ],
)

DM 是 HMLV 的一种具体形式, 其中从 $z_(t-1)$ 到 $z_t$ 的条件分布固定为

$
  q(z_t | z_(t-1)) = cal(N)( sqrt(1-beta_t) z_(t-1), beta_t I), quad 0 < beta_t < 1.
$

其中 $beta_t in RR^+$ 控制每一步加入的噪声量, 使变量沿层级向上变化时, 信噪比逐渐降低. 这里的 $q(z_t | z_(t-1))$ 表示前向加噪的条件分布.

与 VAE 一样, DM 根据一组独立同分布的示范样本学习 $p(o,a)$, 并从容易采样的分布出发生成样本. 不同的是, 经过逐步加噪, 高层变量 $z_T$ 与原始样本 $z_0$ 之间的信息联系可以变得极弱, 因而可以使用上述固定的前向分布 $q(z_t | z_(t-1))$. 反向的条件分布 $p(z_(t-1) | z_t)$ 则通常未知, 需要用 $p_theta (z_(t-1) | z_t)$ 近似. 生成时, 通常从标准高斯分布 $p(z_T)=cal(N)(0,I)$ 采样, 再逐步将 $z_t$ 转换为 $z_(t-1)$, 最终得到接近数据分布的 $z_0$. 这一过程称为去噪.

在这一模型下, 任意样本 $z_0$ 的对数似然可以表示为:

$
  log p_theta (z_0)
  =& log integral_( "supp"(Z_1) times "supp"(Z_2) times dots times "supp"(Z_T) ) p_theta (z_0, z_1, dots, z_T)\
  =& log integral_("supp"(Z_(1:T))) ( p_theta (z_(0:T)) dot q(z_(1:T)|z_0))/(q(z_(1:T)|z_0))\
  =& log EE_(z_(1:T)~q(dot|z_0)) [ (p_theta (z_(0:T)))/(q(z_(1:T)|z_0)) ]\
  >=& EE_(z_(1:T)~q(dot|z_0)) [ log (p_theta (z_(0:T)))/(q(z_(1:T)|z_0)) ]\
  =& EE_(z_(1:T)~q(dot|z_0)) [ log (p(z_T) product_(t=1)^T p_theta (z_(t-1) | z_t)) / (product_(t=1)^(T) q(z_t | z_(t-1)) ) ]\
  =& EE_(z_(1:T)~q(dot|z_0)) [ log (p(z_T) dot p_theta (z_0|z_1) product_(t=2)^T p_theta (z_(t-1) | z_t)) / (q(z_T | z_(T-1)) product_(t=1)^(T-1) q(z_t | z_(t-1)) ) ]\
  =& EE_(z_(1:T)~q(dot|z_0)) [ log (p(z_T) dot p_theta (z_0|z_1) product_(t=1)^(T-1) p_theta (z_(t) | z_(t+1))) / (q(z_T | z_(T-1)) product_(t=1)^(T-1) q(z_t | z_(t-1)) ) ]\
  =& EE_(z_(1:T)~q(dot|z_0)) [ log (p(z_T) dot p_theta (z_0|z_1)) / (q(z_T | z_(T-1)) ) ]+ EE_(z_(1:T)~q(dot|z_0)) [ log product_(t=1)^(T-1) ( p_theta (z_(t) | z_(t+1))) / q(z_t | z_(t-1)) ]\
  =& EE_(z_(1:T)~q(dot|z_0)) [log p_theta (z_0|z_1) ]+EE_(z_(1:T)~q(dot|z_0)) [ log p(z_T) / (q(z_T | z_(T-1)) ) ]+ sum_(t=1)^(T-1) EE_(z_(1:T)~q(dot|z_0)) [ log ( p_theta (z_(t) | z_(t+1))) / q(z_t | z_(t-1)) ]\
  =& EE_(z_1~q(dot|z_0)) [log p_theta (z_0|z_1)] + EE_(z_T~q(dot|z_0)) [log (p(z_T) / q(z_T|z_0))] \
  &+ sum_(t=1)^(T-1) EE_((z_t,z_(t+1))~q(dot|z_0)) [log (p_theta(z_t|z_(t+1)) / q(z_t|z_(t+1),z_0))] \
  =& EE_(z_1~q(dot|z_0)) [log p_theta(z_0|z_1)] - D_"KL" (q(z_T|z_0) || p(z_T)) \
  &- sum_(t=1)^(T-1) EE_(z_(t+1)~q(dot|z_0)) [D_"KL" (q(z_t|z_(t+1),z_0) || p_theta (z_t|z_(t+1)))]
  \ equiv& cal(E)_theta(z_0)
$

上式利用 KL 散度将 $cal(E)_theta(z_0)$ 写成对数似然 $log p_theta(z_0)$ 的变分下界. 训练时通过最大化这一可计算的下界来学习 $p_theta$. Ho 等人（2020）采用固定的各向同性高斯分布, 如 $q(z_t | z_(t-1))=cal(N)(sqrt(1-beta_t)z_(t-1),beta_t I)$, 即前述加噪过程. 在每步方差 $beta_t<= eta, eta in RR^+$ 足够小的条件下, 反向条件分布 $p(z_(t-1) | z_t)$ 也可以用高斯分布表示, 因而可将其近似模型参数化为#footnote[这里的 $mu_theta (z_t,t)$ 是反向高斯分布的均值, $Sigma_theta (z_t,t)$ 是其协方差矩阵; 二者由参数为 $theta$ 的模型根据 $z_t$ 和步数 $t$ 给出.]:

$
  p_theta (z_(t-1) | z_t) = cal(N)(mu_theta (z_t,t), Sigma_theta (z_t,t)), quad t in [1,T].
$

这样, 上式中的 KL 散度项可以直接计算. 此外, 固定高斯加噪过程还使第 $t$ 个潜在变量在给定 $z_0$ 时的分布具有解析形式:

$
  q(z_t | z_0) = cal(N)(sqrt(ov(alpha)_t) z_0, (1-ov(alpha)_t) I), quad
  alpha_t = 1-beta_t, quad ov(alpha)_t = product_(k=1)^t alpha_k.
$

因此, 训练时可以直接从 $q(z_t | z_0)$ 采样, 无须从 $z_0$ 开始逐步加噪.  对上述 $cal(E)_theta (z_0)$ 中与 $theta$ 有关的项求导, 可得

$
  nabla_theta cal(E)_theta (z_0)
  = EE_(z_1~q(dot|z_0)) nabla_theta log p_theta (z_0 | z_1)
  - sum_(t=1)^(T-1) EE_(z_(t+1)~q(dot|z_0)) nabla_theta D_"KL" (q(z_t | z_(t+1),z_0) || p_theta (z_t | z_(t+1)))
$

第一项对应重建项, 后面的 KL 散度项可以解析计算.

除了便于计算, 高斯加噪也使 DM 的学习过程更容易理解. 随着噪声逐步累积, 潜在变量保留的原始样本 $z_0$ 的信息越来越少, 最终接近与样本无关的标准高斯分布. 例如在机器人遥操作数据中, 观测到的关节状态与对应的操作动作通常具有一定关系; 加噪后, 样本逐渐偏离这种关系, 整体分布也随之改变.

因此, 可以把学习反向过程理解为: 估计加噪造成的偏移, 再学习如何逐步消除这种偏移. 根据前述 $q(z_t | z_0)$, 给定示范样本 $z_0$ 、步数 $t$ 和采样的噪声 $epsilon ~ cal(N)(0,I)$, 可以直接构造

$
  z_t = sqrt(ov(alpha)_t) z_0 + sqrt(1-ov(alpha)_t) epsilon.
$

前向加噪、噪声预测和反向采样的输入与输出如下:
#figure(
  table(
    columns: (auto, auto, auto, auto),
    inset: (x: 6pt, y: 5pt),
    stroke: 0.6pt,
    table.header([步骤], [输入], [输出], [输出的用途]),
    [前向加噪（固定）],
    [示范样本 $z_0$ 、步数 $t$ 、噪声 $epsilon$],
    [带噪样本 $z_t$],
    [构造训练样本; 已知的 $epsilon$ 用于监督网络],

    [噪声预测网络 $theta$],
    [ $z_t$ 、 $t$],
    [累计噪声的预测值 $epsilon_theta (z_t, t)$],
    [训练时与 $epsilon$ 比较; 生成时用于计算反向采样的均值],

    [反向采样],
    [ $z_t$ 、 $epsilon_theta (z_t, t)$ 、新采样的噪声],
    [噪声更少的 $z_(t-1)$],
    [从 $z_T$ 开始逐步生成, 直到得到 $z_0$],
  ),
)

训练时直接构造 $z_t$ 来学习噪声预测; 生成时则反复使用同一个网络, 每次采样前进一步:

$
  z_0 stretch(->)^"加噪" z_t stretch(->)^"预测" epsilon_theta (z_t, t)
$

$
  z_T stretch(->)^"反向采样" z_(T-1) -> dots -> z_0.
$

构造 $z_t$ 时使用的 $epsilon$ 是已知的, 因此可以用它作为监督信号, 训练网络预测噪声:

$
  L(theta) = EE_(t,z_0,epsilon) [norm(epsilon-epsilon_theta (sqrt(ov(alpha)_t) z_0+epsilon sqrt(1-ov(alpha)_t),t))^2], quad t~ cal(U)({1,dots,T}),quad z_0~cal(D),quad epsilon~cal(N)(0,I)
$

这个目标不直接最大化样本的对数似然, 而是从示范数据中取 $z_0$, 随机选择加噪步数 $t$, 让网络 $epsilon_theta (z_t, t)$ 预测加入的总噪声 $epsilon$. 训练时调整 $theta$, 使预测噪声尽可能接近实际加入的噪声. 学会预测噪声后, 模型便能从噪声样本出发, 逐步反向恢复接近数据分布的样本.


具体地, 若反向条件分布 $p_theta (z_(t-1)|z_t)$ 为高斯分布, 则一次反向采样可以写为

$
  z_(t-1) = 1/sqrt(alpha_t) (z_t - beta_t/sqrt(1-ov(alpha)_t) epsilon_theta (z_t, t)) + sigma_t epsilon,
  quad epsilon ~ cal(N)(0,I).
$

其中, $epsilon_theta (z_t,t)$ 预测的是从 $z_0$ 加噪到 $z_t$ 时的累计噪声. 利用这一预测, 可以先估计原始样本 $z_0$, 再根据已知的加噪规则求出前一步 $z_(t-1)$ 的条件分布; 将这两步合并, 就得到公式中 $z_(t-1)$ 的采样均值. 最后的 $sigma_t epsilon$ 是围绕该均值采样的随机项. 从 $z_T$ 出发反复应用此式, 便逐渐得到样本 $z_0$.


== 具身强化学习与运动控制 RL

== 生成式策略: Flow Matching

== 通用运动控制: GROOOT 与 SONIC

== 参考文献
