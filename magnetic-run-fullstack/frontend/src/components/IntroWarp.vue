<script setup>
defineProps({
  loadingList: { type: Boolean, default: false },
})

const emit = defineEmits(['enter'])

/** 点缀星球：位置与配色（纯装饰） */
const decoPlanets = [
  { x: '8%', y: '18%', s: 36, delay: '0s', hue: 'cyan' },
  { x: '88%', y: '22%', s: 22, delay: '-2s', hue: 'violet' },
  { x: '14%', y: '72%', s: 28, delay: '-4s', hue: 'magenta' },
  { x: '78%', y: '68%', s: 18, delay: '-1s', hue: 'teal' },
  { x: '92%', y: '48%', s: 14, delay: '-3s', hue: 'orange' },
  { x: '22%', y: '38%', s: 12, delay: '-5s', hue: 'indigo' },
]
</script>

<template>
  <div class="warp">
    <div class="warp__deco" aria-hidden="true">
      <span
        v-for="(p, i) in decoPlanets"
        :key="i"
        class="warp__mini"
        :class="`warp__mini--${p.hue}`"
        :style="{
          left: p.x,
          top: p.y,
          width: `${p.s}px`,
          height: `${p.s}px`,
          animationDelay: p.delay,
        }"
      />
    </div>

    <div class="warp__grid" aria-hidden="true" />
    <div class="warp__stars" aria-hidden="true">
      <span
        v-for="i in 48"
        :key="i"
        class="warp__streak"
        :style="{ '--d': `${(i * 7) % 100}ms`, '--x': `${(i * 13) % 100}%` }"
      />
    </div>
    <div class="warp__tunnel" aria-hidden="true" />

    <div class="warp__content">
      <p class="warp__tag">RUNCENTER // NEURAL LINK</p>
      <h1 class="warp__title">磁性测量</h1>
      <p class="warp__sub">穿越数据断层 · 进入处理星系</p>
      <p v-if="loadingList" class="warp__status">正在同步步骤星图…</p>
      <button type="button" class="warp__btn" @click="emit('enter')">
        进入星系
      </button>
    </div>

    <p class="warp__credit" role="note">设计：王赛赛</p>
  </div>
</template>

<style scoped>
.warp {
  position: fixed;
  inset: 0;
  display: grid;
  place-items: center;
  background: radial-gradient(ellipse 80% 60% at 50% 100%, rgba(0, 255, 240, 0.08), transparent 55%),
    linear-gradient(180deg, #05050a 0%, #0a0e18 45%, #060810 100%);
  overflow: hidden;
  z-index: 10;
}

.warp__deco {
  position: absolute;
  inset: 0;
  pointer-events: none;
  z-index: 1;
}

.warp__mini {
  position: absolute;
  border-radius: 50%;
  transform: translate(-50%, -50%);
  opacity: 0.75;
  animation: mini-float 8s ease-in-out infinite;
}

.warp__mini--cyan {
  background: radial-gradient(circle at 32% 28%, #b8fff8, #0a3d4a 70%);
  box-shadow: 0 0 24px rgba(0, 255, 240, 0.35);
}

.warp__mini--violet {
  background: radial-gradient(circle at 32% 28%, #e8d8ff, #3d2a55 70%);
  box-shadow: 0 0 20px rgba(167, 139, 250, 0.35);
}

.warp__mini--magenta {
  background: radial-gradient(circle at 32% 28%, #ffd0ec, #4a2040 70%);
  box-shadow: 0 0 22px rgba(255, 42, 160, 0.3);
}

.warp__mini--teal {
  background: radial-gradient(circle at 32% 28%, #b8ffe8, #0d3530 70%);
  box-shadow: 0 0 16px rgba(52, 211, 153, 0.3);
}

.warp__mini--orange {
  background: radial-gradient(circle at 32% 28%, #ffe0c0, #4a3010 70%);
  box-shadow: 0 0 14px rgba(251, 146, 60, 0.28);
}

.warp__mini--indigo {
  background: radial-gradient(circle at 32% 28%, #d8dcff, #252a4a 70%);
  box-shadow: 0 0 12px rgba(129, 140, 248, 0.3);
}

@keyframes mini-float {
  0%,
  100% {
    transform: translate(-50%, -50%) scale(1);
  }
  50% {
    transform: translate(-50%, calc(-50% - 6px)) scale(1.04);
  }
}

.warp__credit {
  position: absolute;
  bottom: 1.1rem;
  left: 1.25rem;
  z-index: 5;
  margin: 0;
  font-family: var(--font-mono, ui-monospace, monospace);
  font-size: 0.72rem;
  letter-spacing: 0.12em;
  color: rgba(200, 215, 235, 0.65);
  text-shadow: 0 0 12px rgba(0, 255, 240, 0.2);
  pointer-events: none;
}

.warp__grid {
  position: absolute;
  inset: -50%;
  background-image: linear-gradient(rgba(0, 255, 240, 0.04) 1px, transparent 1px),
    linear-gradient(90deg, rgba(255, 0, 170, 0.03) 1px, transparent 1px);
  background-size: 48px 48px;
  transform: perspective(400px) rotateX(60deg);
  animation: grid-drift 20s linear infinite;
}

.warp__tunnel {
  position: absolute;
  inset: 0;
  background: radial-gradient(circle at 50% 50%, transparent 0%, transparent 18%, rgba(5, 5, 12, 0.85) 42%);
  pointer-events: none;
}

.warp__stars {
  position: absolute;
  inset: 0;
  pointer-events: none;
}

.warp__streak {
  position: absolute;
  left: var(--x);
  top: -10%;
  width: 2px;
  height: 18%;
  background: linear-gradient(180deg, transparent, rgba(0, 255, 240, 0.85), transparent);
  opacity: 0.55;
  animation: streak 2.2s ease-in infinite;
  animation-delay: var(--d);
}

.warp__content {
  position: relative;
  z-index: 2;
  text-align: center;
  padding: 1.5rem;
}

.warp__tag {
  font-family: var(--font-mono, ui-monospace, monospace);
  font-size: 0.7rem;
  letter-spacing: 0.35em;
  color: rgba(0, 255, 240, 0.65);
  margin: 0 0 1rem;
}

.warp__title {
  font-family: var(--font-display, system-ui, sans-serif);
  font-size: clamp(2rem, 6vw, 3.25rem);
  font-weight: 700;
  margin: 0;
  letter-spacing: 0.12em;
  background: linear-gradient(120deg, #00fff0 0%, #a78bfa 45%, #ff2aa0 100%);
  -webkit-background-clip: text;
  background-clip: text;
  color: transparent;
  text-shadow: 0 0 40px rgba(0, 255, 240, 0.35);
}

.warp__sub {
  margin: 0.75rem 0 1.5rem;
  font-size: 0.95rem;
  color: rgba(200, 210, 230, 0.75);
}

.warp__status {
  font-family: var(--font-mono, monospace);
  font-size: 0.8rem;
  color: rgba(255, 170, 0, 0.85);
  margin: 0 0 1rem;
}

.warp__btn {
  font-family: var(--font-display, system-ui, sans-serif);
  font-size: 0.95rem;
  letter-spacing: 0.2em;
  padding: 0.85rem 2.25rem;
  border: 1px solid rgba(0, 255, 240, 0.55);
  border-radius: 2px;
  background: rgba(0, 255, 240, 0.08);
  color: #b8fff9;
  cursor: pointer;
  box-shadow: 0 0 24px rgba(0, 255, 240, 0.2), inset 0 0 20px rgba(0, 255, 240, 0.06);
  transition: transform 0.15s ease-out, box-shadow 0.2s, border-color 0.2s;
}

.warp__btn:hover {
  transform: scale(1.03);
  border-color: #00fff0;
  box-shadow: 0 0 36px rgba(0, 255, 240, 0.35);
}

.warp__btn:focus-visible {
  outline: 2px solid #00fff0;
  outline-offset: 3px;
}

@keyframes streak {
  0% {
    transform: translateY(-20%) scaleY(0.3);
    opacity: 0;
  }
  15% {
    opacity: 0.8;
  }
  100% {
    transform: translateY(120vh) scaleY(1.8);
    opacity: 0;
  }
}

@keyframes grid-drift {
  0% {
    transform: perspective(400px) rotateX(60deg) translateY(0);
  }
  100% {
    transform: perspective(400px) rotateX(60deg) translateY(48px);
  }
}

@media (prefers-reduced-motion: reduce) {
  .warp__grid,
  .warp__streak,
  .warp__mini {
    animation: none;
  }
  .warp__streak {
    opacity: 0.25;
    top: 40%;
  }
  .warp__btn:hover {
    transform: none;
  }
}
</style>
