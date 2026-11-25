<template>
  <div class="home">
    <section class="hero">
      <div class="wrap hero-in">
        <div class="txt">
          <div class="eyebrow">SKIN FIRST · 先试后买</div>
          <h1>把「适不适合」<br />交给 7 天的试用装</h1>
          <p>按肤质档案智能匹配小样，免费申领、顺丰寄出；用完提交试用报告，可解锁正装专属折扣。</p>
          <div class="cta">
            <el-button type="primary" size="large" @click="$router.push('/portal/trial')">免费领试用装</el-button>
            <el-button size="large" @click="$router.push('/portal/skin-test')">先做肤质测评</el-button>
          </div>
          <div class="stats">
            <div><b>{{ goods.length }}</b><span>在售正装</span></div>
            <div><b>{{ samples.length }}</b><span>可派小样</span></div>
            <div><b>30</b><span>天报告周期</span></div>
          </div>
        </div>
        <div class="vis">
          <img :src="heroImg" alt="LUMA 试用装" />
          <div class="badge">本期主推 · 屏障修护</div>
        </div>
      </div>
    </section>

    <section class="wrap blk">
      <div class="blk-hd">
        <div>
          <h2>今日可领试用装</h2>
          <p>库存与效期实时同步，派完即止</p>
        </div>
        <router-link class="more" to="/portal/trial">全部试用 →</router-link>
      </div>
      <div class="grid4">
        <div v-for="s in samples" :key="s.id" class="scard" @click="goSample(s)">
          <div class="cov"><img :src="s.goodsCover" alt="" /><span class="ml">{{ s.specMl }}ml</span></div>
          <div class="bd">
            <div class="nm">{{ s.goodsName }}</div>
            <div class="sub">批次 {{ s.batchNo }} · 余 {{ s.remainQty }} 份</div>
            <div class="row">
              <span class="free">免费</span>
              <span class="tag" :class="s.expiring ? 'warn' : 'ok'">{{ s.expiring ? '临期批次' : '效期充足' }}</span>
            </div>
          </div>
        </div>
        <el-empty v-if="!samples.length" description="暂无可领试用装" />
      </div>
    </section>

    <section class="wrap blk">
      <div class="blk-hd">
        <div>
          <h2>试用后想入手 · 正装推荐</h2>
          <p>提交过报告的用户下单自动叠加 9 折</p>
        </div>
        <router-link class="more" to="/portal/orders">我的订单 →</router-link>
      </div>
      <div class="grid4">
        <div v-for="g in goods" :key="g.id" class="gcard" @click="$router.push(`/portal/goods/${g.id}`)">
          <div class="cov"><img :src="g.coverImage" alt="" /></div>
          <div class="bd">
            <div class="nm">{{ g.goodsName }}</div>
            <div class="sub">{{ g.brand }} · {{ g.specMl }}ml · {{ g.effectTags }}</div>
            <div class="row">
              <span class="price">¥{{ money(g.salePrice) }}</span>
              <span class="tag" :class="g.isTrial ? 'ok' : 'info'">{{ g.isTrial ? '可领小样' : '正装' }}</span>
            </div>
          </div>
        </div>
      </div>
    </section>

    <section class="wrap blk">
      <div class="steps">
        <div class="st"><b>01</b><h4>建档</h4><p>3 分钟肤质测评，生成专属档案</p></div>
        <div class="st"><b>02</b><h4>申领</h4><p>按档案匹配小样，审核通过即寄出</p></div>
        <div class="st"><b>03</b><h4>试用</h4><p>连续使用 7 天，记录肤感变化</p></div>
        <div class="st"><b>04</b><h4>报告</h4><p>提交报告解锁正装折扣与积分</p></div>
      </div>
    </section>
  </div>
</template>

<script setup>
import { ref, onMounted } from 'vue'
import { useRouter } from 'vue-router'
import { goodsPage, samplePage } from '../../api'
import { money } from '../../utils/format'

const router = useRouter()
const goods = ref([])
const samples = ref([])
const heroImg = ref('')

const load = async () => {
  const [g, s] = await Promise.all([
    goodsPage({ page: 1, size: 8, status: '在售' }),
    samplePage({ page: 1, size: 4, status: '可派发' })
  ])
  goods.value = g.data.records || []
  samples.value = s.data.records || []
  heroImg.value = goods.value[0]?.coverImage || ''
}

const goSample = (s) => {
  if (s.goodsId) router.push(`/portal/goods/${s.goodsId}`)
  else router.push('/portal/trial')
}

onMounted(load)
</script>

<style scoped>
.wrap { width: 1200px; margin: 0 auto; }
.hero { background: linear-gradient(120deg, #f6f1fb 0%, #fdf7f2 55%, #f3f0fa 100%); border-bottom: 1px solid var(--bt-line); }
.hero-in { display: flex; align-items: center; gap: 56px; padding: 54px 0 48px; }
.txt { flex: 1; }
.eyebrow { font-size: 11px; letter-spacing: 2.4px; color: var(--bt-primary); font-weight: 600; }
.hero h1 { font-size: 40px; line-height: 1.28; margin: 14px 0 14px; letter-spacing: -0.5px; }
.hero p { font-size: 14px; color: var(--bt-text-2); line-height: 1.9; max-width: 460px; }
.cta { display: flex; gap: 12px; margin: 24px 0 26px; }
.stats { display: flex; gap: 42px; }
.stats b { font-size: 22px; color: var(--bt-primary); }
.stats span { display: block; font-size: 12px; color: var(--bt-text-3); margin-top: 2px; }
.vis { width: 380px; height: 320px; position: relative; flex: none; }
.vis img { width: 100%; height: 100%; object-fit: cover; border-radius: 20px; box-shadow: 0 18px 40px rgba(90, 60, 130, .18); }
.badge { position: absolute; left: 16px; bottom: 16px; background: rgba(255, 255, 255, .92); padding: 7px 14px; border-radius: 999px; font-size: 12px; color: var(--bt-primary); font-weight: 600; }
.blk { padding: 34px 0 6px; }
.blk-hd { display: flex; align-items: flex-end; justify-content: space-between; margin-bottom: 16px; }
.blk-hd h2 { font-size: 20px; margin: 0 0 4px; }
.blk-hd p { font-size: 12px; color: var(--bt-text-3); margin: 0; }
.more { font-size: 12px; color: var(--bt-primary); }
.grid4 { display: grid; grid-template-columns: repeat(4, 1fr); gap: 16px; }
.scard, .gcard { background: #fff; border: 1px solid var(--bt-line); border-radius: 14px; overflow: hidden; cursor: pointer; transition: .18s; }
.scard:hover, .gcard:hover { transform: translateY(-3px); box-shadow: 0 14px 28px rgba(90, 60, 130, .12); border-color: #e2d6f0; }
.cov { position: relative; height: 168px; background: #f7f3fb; }
.cov img { width: 100%; height: 100%; object-fit: cover; }
.ml { position: absolute; right: 10px; top: 10px; background: rgba(255,255,255,.94); border-radius: 6px; font-size: 11px; padding: 3px 7px; color: var(--bt-primary); font-weight: 600; }
.bd { padding: 12px 13px 14px; }
.nm { font-size: 14px; font-weight: 600; white-space: nowrap; overflow: hidden; text-overflow: ellipsis; }
.sub { font-size: 11px; color: var(--bt-text-3); margin: 5px 0 10px; white-space: nowrap; overflow: hidden; text-overflow: ellipsis; }
.row { display: flex; align-items: center; justify-content: space-between; }
.free { font-size: 14px; font-weight: 700; color: #b6652f; }
.steps { display: grid; grid-template-columns: repeat(4, 1fr); gap: 16px; background: #faf8fd; border-radius: 16px; padding: 20px; margin-bottom: 34px; }
.st b { font-size: 12px; color: var(--bt-primary); letter-spacing: 1px; }
.st h4 { font-size: 14px; margin: 6px 0 4px; }
.st p { font-size: 12px; color: var(--bt-text-3); margin: 0; line-height: 1.7; }
</style>
