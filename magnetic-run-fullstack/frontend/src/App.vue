<script setup>
import { ref, onMounted } from 'vue'
import IntroWarp from './components/IntroWarp.vue'
import PlanetMap from './components/PlanetMap.vue'
import RunWorkbench from './components/RunWorkbench.vue'
import { useRunCenter } from './composables/useRunCenter'

const phase = ref('intro')
const { loadingList, fetchSteps } = useRunCenter()

onMounted(() => {
  fetchSteps()
})

function enterGalaxy() {
  phase.value = 'map'
}

function toWorkbench() {
  phase.value = 'workbench'
}

function backToMap() {
  phase.value = 'map'
}
</script>

<template>
  <div class="app-root">
    <Transition name="fade">
      <IntroWarp v-if="phase === 'intro'" :loading-list="loadingList" @enter="enterGalaxy" />
    </Transition>

    <div v-show="phase !== 'intro'" class="app-shell">
      <Transition name="slide" mode="out-in">
        <PlanetMap v-if="phase === 'map'" key="map" @to-workbench="toWorkbench" />
        <RunWorkbench v-else-if="phase === 'workbench'" key="wb" @back="backToMap" />
      </Transition>
    </div>
  </div>
</template>

<style scoped>
.app-root {
  min-height: 100svh;
}

.app-shell {
  min-height: 100svh;
  background: radial-gradient(ellipse 100% 80% at 50% -20%, rgba(120, 80, 200, 0.12), transparent 50%),
    linear-gradient(180deg, #06060c 0%, #0a0e18 40%, #070810 100%);
}

.fade-enter-active,
.fade-leave-active {
  transition: opacity 0.55s ease;
}
.fade-enter-from,
.fade-leave-to {
  opacity: 0;
}

.slide-enter-active,
.slide-leave-active {
  transition: opacity 0.35s ease, transform 0.35s ease;
}
.slide-enter-from {
  opacity: 0;
  transform: translateY(12px);
}
.slide-leave-to {
  opacity: 0;
  transform: translateY(-8px);
}

@media (prefers-reduced-motion: reduce) {
  .fade-enter-active,
  .fade-leave-active,
  .slide-enter-active,
  .slide-leave-active {
    transition: none;
  }
}
</style>
