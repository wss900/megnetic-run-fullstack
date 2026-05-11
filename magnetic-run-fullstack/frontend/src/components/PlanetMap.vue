<script setup>
import { computed } from 'vue'
import { useRunCenter } from '../composables/useRunCenter'

const emit = defineEmits(['to-workbench'])

const { categories, category, stepId, stepsInCat, loadingList, error, steps } = useRunCenter()

const palettes = [
  { core: '#0d2137', glow: '#00e8ff', ring: 'rgba(0, 232, 255, 0.45)' },
  { core: '#2a0d35', glow: '#e879f9', ring: 'rgba(232, 121, 249, 0.45)' },
  { core: '#0d2a24', glow: '#34d399', ring: 'rgba(52, 211, 153, 0.45)' },
  { core: '#2c1a0d', glow: '#fb923c', ring: 'rgba(251, 146, 60, 0.45)' },
  { core: '#1a1a3d', glow: '#818cf8', ring: 'rgba(129, 140, 248, 0.45)' },
]

function paletteFor(i) {
  return palettes[i % palettes.length]
}

const selectedPalette = computed(() => {
  const i = categories.value.indexOf(category.value)
  return paletteFor(i >= 0 ? i : 0)
})

function selectCat(c) {
  category.value = c
}
</script>

<template>
  <div class="map">
    <header class="map__head">
      <div>
        <p class="map__crumb">SECTOR // TOOL ORBIT</p>
        <h1 class="map__title">选择星系</h1>
        <p class="map__hint">每个星球代表一类工具；选定后选择具体步骤，再进入处理终端。</p>
      </div>
    </header>

    <p v-if="loadingList" class="map__loading">加载星图数据…</p>
    <p v-else-if="error" class="map__err">{{ error }}</p>

    <div v-else-if="steps.length" class="map__body">
      <div class="map__planets">
        <button
          v-for="(c, i) in categories"
          :key="c"
          type="button"
          class="planet"
          :class="{ 'planet--active': category === c }"
          :style="{
            '--core': paletteFor(i).core,
            '--glow': paletteFor(i).glow,
            '--ring': paletteFor(i).ring,
          }"
          @click="selectCat(c)"
        >
          <span class="planet__sphere" />
          <span class="planet__ring" />
          <span class="planet__label">{{ c }}</span>
        </button>
      </div>

      <section class="orbit-panel">
        <h2 class="orbit-panel__h">当前轨道 · 步骤</h2>
        <p class="orbit-panel__cat" :style="{ color: selectedPalette.glow }">{{ category }}</p>
        <div class="orbit-panel__steps">
          <button
            v-for="s in stepsInCat"
            :key="s.id"
            type="button"
            class="step-chip"
            :class="{ 'step-chip--on': stepId === s.id }"
            @click="stepId = s.id"
          >
            {{ s.name }}
          </button>
        </div>
        <button type="button" class="map__launch" :disabled="!stepId" @click="emit('to-workbench')">
          进入处理终端 →
        </button>
      </section>
    </div>

    <div v-else class="map__empty">
      <p class="map__empty-title">暂无可用步骤</p>
      <p class="map__empty-hint">
        静态网页托管（如 EdgeOne Pages）本身不提供 <code>/api</code> 接口。请在腾讯云部署 FastAPI 后端，并在构建时设置环境变量
        <code>VITE_API_BASE</code> 为后端根地址（例如 <code>https://api.example.com</code>），同时在该后端放行本站域名的 CORS。
      </p>
    </div>
  </div>
</template>

<style scoped>
.map {
  max-width: 960px;
  margin: 0 auto;
  padding: 1.5rem 1.25rem 3rem;
}

.map__head {
  margin-bottom: 1.5rem;
}

.map__crumb {
  font-family: var(--font-mono, monospace);
  font-size: 0.65rem;
  letter-spacing: 0.28em;
  color: rgba(0, 255, 240, 0.5);
  margin: 0 0 0.35rem;
}

.map__title {
  font-family: var(--font-display, system-ui, sans-serif);
  font-size: 1.5rem;
  margin: 0 0 0.35rem;
  color: #e8ecf4;
  letter-spacing: 0.06em;
}

.map__hint {
  margin: 0;
  font-size: 0.88rem;
  color: rgba(180, 190, 210, 0.75);
  max-width: 36rem;
}

.map__loading {
  color: rgba(0, 255, 240, 0.7);
  font-family: var(--font-mono, monospace);
  font-size: 0.85rem;
}

.map__err {
  color: #ff6b9d;
  font-size: 0.9rem;
  line-height: 1.5;
}

.map__empty {
  max-width: 40rem;
  padding: 1.5rem 0;
  font-size: 0.88rem;
  line-height: 1.65;
  color: rgba(200, 210, 230, 0.88);
}

.map__empty-title {
  margin: 0 0 0.75rem;
  font-size: 1rem;
  font-weight: 600;
  color: #e8ecf4;
}

.map__empty-hint {
  margin: 0;
  color: rgba(180, 195, 220, 0.8);
}

.map__empty code {
  font-family: var(--font-mono, monospace);
  font-size: 0.82em;
  padding: 0.1em 0.35em;
  border-radius: 3px;
  background: rgba(0, 255, 240, 0.08);
  color: rgba(0, 255, 240, 0.9);
}

.map__body {
  display: flex;
  flex-direction: column;
  gap: 2rem;
}

.map__planets {
  display: flex;
  flex-wrap: wrap;
  gap: 1.25rem 1.5rem;
  justify-content: center;
  padding: 1rem 0;
}

.planet {
  position: relative;
  width: 120px;
  height: 120px;
  border: none;
  background: transparent;
  cursor: pointer;
  padding: 0;
  flex-shrink: 0;
}

.planet:focus-visible {
  outline: 2px solid var(--glow, #00fff0);
  outline-offset: 4px;
  border-radius: 8px;
}

.planet__sphere {
  position: absolute;
  inset: 18%;
  border-radius: 50%;
  background: radial-gradient(circle at 32% 28%, color-mix(in srgb, var(--glow) 55%, white), var(--core));
  box-shadow: 0 0 28px color-mix(in srgb, var(--glow) 40%, transparent), inset 0 -8px 16px rgba(0, 0, 0, 0.45);
  transition: transform 0.25s, box-shadow 0.25s;
}

.planet__ring {
  position: absolute;
  inset: 8%;
  border-radius: 50%;
  border: 2px solid var(--ring);
  opacity: 0.55;
  transform: rotateX(72deg);
  box-shadow: 0 0 12px var(--ring);
}

.planet__label {
  position: absolute;
  left: 50%;
  bottom: -1.65rem;
  transform: translateX(-50%);
  width: 140%;
  font-size: 0.72rem;
  line-height: 1.25;
  color: rgba(200, 210, 230, 0.9);
  text-align: center;
  display: -webkit-box;
  -webkit-line-clamp: 2;
  -webkit-box-orient: vertical;
  overflow: hidden;
}

.planet:hover .planet__sphere {
  transform: scale(1.06);
  box-shadow: 0 0 40px color-mix(in srgb, var(--glow) 55%, transparent);
}

.planet--active .planet__sphere {
  transform: scale(1.08);
  box-shadow: 0 0 48px color-mix(in srgb, var(--glow) 65%, transparent);
}

.planet--active .planet__ring {
  opacity: 1;
  border-color: var(--glow);
}

.orbit-panel {
  border: 1px solid rgba(0, 255, 240, 0.2);
  border-radius: 4px;
  padding: 1.25rem;
  background: rgba(10, 14, 28, 0.65);
  backdrop-filter: blur(8px);
  box-shadow: 0 0 40px rgba(0, 0, 0, 0.35), inset 0 1px 0 rgba(255, 255, 255, 0.04);
}

.orbit-panel__h {
  font-size: 0.75rem;
  font-family: var(--font-mono, monospace);
  letter-spacing: 0.15em;
  color: rgba(0, 255, 240, 0.55);
  margin: 0 0 0.35rem;
  font-weight: 600;
}

.orbit-panel__cat {
  margin: 0 0 1rem;
  font-size: 1rem;
  font-weight: 600;
}

.orbit-panel__steps {
  display: flex;
  flex-wrap: wrap;
  gap: 0.5rem;
  margin-bottom: 1.25rem;
}

.step-chip {
  font-size: 0.8rem;
  padding: 0.45rem 0.75rem;
  border-radius: 2px;
  border: 1px solid rgba(255, 255, 255, 0.12);
  background: rgba(255, 255, 255, 0.04);
  color: #c8d0e0;
  cursor: pointer;
  transition: border-color 0.15s, box-shadow 0.15s;
}

.step-chip:focus-visible {
  outline: 2px solid #00fff0;
  outline-offset: 2px;
}

.step-chip:hover {
  border-color: rgba(0, 255, 240, 0.35);
}

.step-chip--on {
  border-color: rgba(0, 255, 240, 0.65);
  box-shadow: 0 0 14px rgba(0, 255, 240, 0.15);
  color: #e8fff8;
}

.map__launch {
  font-family: var(--font-display, system-ui, sans-serif);
  font-size: 0.9rem;
  letter-spacing: 0.12em;
  padding: 0.65rem 1.25rem;
  border: 1px solid rgba(255, 42, 160, 0.5);
  border-radius: 2px;
  background: rgba(255, 42, 160, 0.12);
  color: #ffc8e8;
  cursor: pointer;
  transition: box-shadow 0.2s;
}

.map__launch:focus-visible {
  outline: 2px solid #ff2aa0;
  outline-offset: 3px;
}

.map__launch:hover:not(:disabled) {
  box-shadow: 0 0 24px rgba(255, 42, 160, 0.25);
}

.map__launch:disabled {
  opacity: 0.35;
  cursor: not-allowed;
}
</style>
