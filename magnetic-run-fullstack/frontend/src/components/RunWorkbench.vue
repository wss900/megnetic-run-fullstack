<script setup>
import { ref, watch } from 'vue'
import { useRunCenter } from '../composables/useRunCenter'

const emit = defineEmits(['back'])

const descOpen = ref(false)

const {
  currentStep,
  acceptAttr,
  fileInput,
  paramValues,
  loadingRun,
  result,
  error,
  onFiles,
  run,
  saveDownload,
} = useRunCenter()

watch(currentStep, () => {
  descOpen.value = false
})
</script>

<template>
  <div class="wb">
    <header class="wb__bar">
      <button type="button" class="wb__back" @click="emit('back')">← 返回星图</button>
      <div class="wb__bar-mid">
        <span class="wb__tag">TERMINAL</span>
        <h1 class="wb__title">处理终端</h1>
      </div>
      <span class="wb__spacer" />
    </header>

    <p v-if="error" class="wb__err">{{ error }}</p>

    <div v-if="currentStep" class="wb__layout">
      <section class="panel">
        <h2 class="panel__h">{{ currentStep.name }}</h2>
        <details class="desc-details" :open="descOpen" @toggle="descOpen = $event.target.open">
          <summary class="desc-details__summary">
            <span class="desc-details__label">步骤说明</span>
            <span class="desc-details__hint" aria-hidden="true">{{ descOpen ? '收起' : '展开' }}</span>
          </summary>
          <div class="panel__desc-wrap">
            <p class="panel__desc">{{ currentStep.description }}</p>
          </div>
        </details>
        <p class="panel__meta">ID <code class="wb__code">{{ currentStep.id }}</code></p>
      </section>

      <section class="panel">
        <h3 class="panel__sh">上传文件</h3>
        <p v-if="!currentStep.file_types.length" class="muted">本步骤可不选文件。</p>
        <input
          v-else
          ref="fileInput"
          type="file"
          multiple
          :accept="acceptAttr"
          class="wb__file"
          @change="onFiles"
        />
      </section>

      <section v-if="currentStep.params.length" class="panel">
        <h3 class="panel__sh">参数</h3>
        <div class="params">
          <template v-for="p in currentStep.params" :key="p.key">
            <label class="plabel">{{ p.label }}</label>
            <input
              v-if="p.kind === 'int' || p.kind === 'float'"
              v-model.number="paramValues[p.key]"
              type="number"
              class="wb__ctl"
              :step="p.kind === 'int' ? 1 : 'any'"
            />
            <input v-else-if="p.kind === 'bool'" v-model="paramValues[p.key]" type="checkbox" class="wb__check" />
            <select v-else-if="p.kind === 'select'" v-model="paramValues[p.key]" class="wb__ctl">
              <option v-for="opt in p.options || []" :key="opt" :value="opt">{{ opt }}</option>
            </select>
            <input v-else v-model="paramValues[p.key]" type="text" class="wb__ctl" />
          </template>
        </div>
      </section>

      <button type="button" class="wb__run" :disabled="loadingRun" @click="run">
        {{ loadingRun ? '执行中…' : '▶ 执行处理' }}
      </button>

      <section v-if="result" class="panel panel--out">
        <h3 class="panel__sh panel__sh--accent">输出</h3>
        <p v-for="(n, i) in result.notes" :key="i" class="note">{{ n }}</p>

        <div v-for="(rows, name) in result.tables" :key="name" class="block">
          <h4 class="out-h">{{ name }}</h4>
          <div class="table-wrap">
            <table v-if="rows.length">
              <thead>
                <tr>
                  <th v-for="col in Object.keys(rows[0])" :key="col">{{ col }}</th>
                </tr>
              </thead>
              <tbody>
                <tr v-for="(row, ri) in rows" :key="ri">
                  <td v-for="col in Object.keys(rows[0])" :key="col">{{ row[col] }}</td>
                </tr>
              </tbody>
            </table>
            <p v-else class="muted">空表</p>
          </div>
        </div>

        <div v-for="(img, name) in result.images" :key="'img-' + name" class="block">
          <h4 class="out-h">{{ name }}</h4>
          <img :alt="img.filename" :src="`data:${img.mime};base64,${img.base64}`" class="img" />
          <button type="button" class="linkbtn" @click="saveDownload(img.filename, img.mime, img.base64)">
            下载 {{ img.filename }}
          </button>
        </div>

        <div v-for="(dl, name) in result.downloads" :key="'dl-' + name" class="block">
          <h4 class="out-h">{{ name }}</h4>
          <button type="button" class="linkbtn" @click="saveDownload(dl.filename, dl.mime, dl.base64)">
            下载 {{ dl.filename }}
          </button>
        </div>
      </section>
    </div>
  </div>
</template>

<style scoped>
.wb {
  max-width: 920px;
  margin: 0 auto;
  padding: 1rem 1.25rem 3rem;
}

.wb__bar {
  display: flex;
  align-items: center;
  justify-content: space-between;
  gap: 1rem;
  margin-bottom: 1.25rem;
  padding-bottom: 1rem;
  border-bottom: 1px solid rgba(0, 255, 240, 0.15);
}

.wb__back {
  font-family: var(--font-mono, monospace);
  font-size: 0.8rem;
  padding: 0.4rem 0.75rem;
  border: 1px solid rgba(255, 255, 255, 0.15);
  border-radius: 2px;
  background: rgba(255, 255, 255, 0.04);
  color: #b8c4d8;
  cursor: pointer;
}

.wb__back:hover {
  border-color: rgba(0, 255, 240, 0.4);
  color: #e8fff8;
}

.wb__bar-mid {
  text-align: center;
}

.wb__tag {
  display: block;
  font-family: var(--font-mono, monospace);
  font-size: 0.6rem;
  letter-spacing: 0.35em;
  color: rgba(0, 255, 240, 0.45);
  margin-bottom: 0.2rem;
}

.wb__title {
  font-family: var(--font-display, system-ui, sans-serif);
  font-size: 1.15rem;
  margin: 0;
  color: #e8ecf4;
  letter-spacing: 0.08em;
}

.wb__spacer {
  width: 7rem;
}

.wb__err {
  color: #ff6b9d;
  font-size: 0.88rem;
  margin: 0 0 1rem;
  padding: 0.65rem 0.85rem;
  border-left: 3px solid #ff2aa0;
  background: rgba(255, 42, 160, 0.08);
}

.wb__layout {
  display: flex;
  flex-direction: column;
  gap: 1rem;
}

.panel {
  border: 1px solid rgba(0, 255, 240, 0.18);
  border-radius: 4px;
  padding: 1rem 1.1rem;
  background: rgba(8, 12, 24, 0.72);
  box-shadow: inset 0 1px 0 rgba(255, 255, 255, 0.04);
}

.panel--out {
  border-color: rgba(167, 139, 250, 0.25);
  background: rgba(12, 10, 22, 0.75);
}

.panel__h {
  font-size: 1.1rem;
  margin: 0 0 0.5rem;
  color: #f0f4fc;
}

.desc-details {
  margin: 0.5rem 0 0.75rem;
  border: 1px solid rgba(0, 255, 240, 0.15);
  border-radius: 4px;
  background: rgba(0, 0, 0, 0.2);
}

.desc-details__summary {
  list-style: none;
  cursor: pointer;
  display: flex;
  align-items: center;
  justify-content: space-between;
  gap: 0.75rem;
  padding: 0.55rem 0.75rem;
  font-size: 0.8rem;
  font-family: var(--font-mono, monospace);
  letter-spacing: 0.12em;
  color: rgba(0, 255, 240, 0.75);
  user-select: none;
}

.desc-details__summary::-webkit-details-marker {
  display: none;
}

.desc-details__summary::marker {
  content: '';
}

.desc-details__summary:focus-visible {
  outline: 2px solid #00fff0;
  outline-offset: 2px;
  border-radius: 2px;
}

.desc-details__hint {
  font-size: 0.72rem;
  letter-spacing: 0.08em;
  color: rgba(200, 210, 230, 0.55);
}

.panel__desc-wrap {
  padding: 0 0.75rem 0.75rem;
  animation: desc-open 0.22s ease-out;
}

@keyframes desc-open {
  from {
    opacity: 0;
    transform: translateY(-4px);
  }
  to {
    opacity: 1;
    transform: translateY(0);
  }
}

@media (prefers-reduced-motion: reduce) {
  .panel__desc-wrap {
    animation: none;
  }
}

.panel__sh {
  font-size: 0.72rem;
  font-family: var(--font-mono, monospace);
  letter-spacing: 0.2em;
  color: rgba(0, 255, 240, 0.55);
  margin: 0 0 0.65rem;
  font-weight: 600;
}

.panel__sh--accent {
  color: rgba(167, 139, 250, 0.85);
}

.panel__desc {
  white-space: pre-wrap;
  margin: 0;
  font-size: 0.9rem;
  line-height: 1.55;
  color: rgba(200, 210, 230, 0.88);
}

.panel__meta {
  margin: 0.75rem 0 0;
  font-size: 0.78rem;
  color: rgba(160, 170, 190, 0.7);
}

.wb__code {
  font-family: var(--font-mono, monospace);
  font-size: 0.78rem;
  padding: 0.15rem 0.4rem;
  background: rgba(0, 255, 240, 0.08);
  border: 1px solid rgba(0, 255, 240, 0.2);
  border-radius: 2px;
  color: #7ee8dc;
}

.muted {
  color: rgba(150, 165, 190, 0.75);
  font-size: 0.88rem;
}

.wb__file {
  width: 100%;
  font-size: 0.85rem;
  color: #c8d4e8;
}

.wb__ctl {
  width: 100%;
  padding: 0.45rem 0.55rem;
  box-sizing: border-box;
  border: 1px solid rgba(255, 255, 255, 0.12);
  border-radius: 2px;
  background: rgba(0, 0, 0, 0.35);
  color: #e8ecf4;
  font-size: 0.88rem;
}

.wb__check {
  width: 1.1rem;
  height: 1.1rem;
  accent-color: #00fff0;
}

.params {
  display: grid;
  grid-template-columns: 140px 1fr;
  gap: 0.5rem 0.75rem;
  align-items: center;
}

.plabel {
  font-size: 0.85rem;
  color: rgba(200, 210, 230, 0.85);
}

.wb__run {
  font-family: var(--font-display, system-ui, sans-serif);
  font-size: 0.9rem;
  letter-spacing: 0.15em;
  padding: 0.7rem 1.5rem;
  align-self: flex-start;
  border: 1px solid rgba(0, 255, 240, 0.55);
  border-radius: 2px;
  background: linear-gradient(180deg, rgba(0, 255, 240, 0.18), rgba(0, 255, 240, 0.06));
  color: #c8fff8;
  cursor: pointer;
  box-shadow: 0 0 20px rgba(0, 255, 240, 0.12);
}

.wb__run:hover:not(:disabled) {
  box-shadow: 0 0 28px rgba(0, 255, 240, 0.28);
}

.wb__run:disabled {
  opacity: 0.5;
  cursor: not-allowed;
}

.note {
  background: rgba(0, 255, 240, 0.06);
  border-left: 3px solid rgba(0, 255, 240, 0.45);
  padding: 0.5rem 0.75rem;
  margin: 0 0 0.75rem;
  font-size: 0.88rem;
  color: #d0e8e4;
}

.out-h {
  font-size: 0.85rem;
  margin: 0 0 0.35rem;
  color: #c4b5fd;
}

.table-wrap {
  overflow: auto;
  max-height: 360px;
  border: 1px solid rgba(255, 255, 255, 0.08);
  border-radius: 2px;
}

table {
  border-collapse: collapse;
  font-size: 0.8rem;
  font-family: var(--font-mono, monospace);
  width: 100%;
}

th,
td {
  border: 1px solid rgba(255, 255, 255, 0.1);
  padding: 0.3rem 0.5rem;
  color: #d0d8e8;
}

th {
  background: rgba(167, 139, 250, 0.12);
  color: #e8e0ff;
}

.img {
  max-width: 100%;
  height: auto;
  border-radius: 2px;
  border: 1px solid rgba(255, 255, 255, 0.1);
}

.linkbtn {
  margin-top: 0.35rem;
  background: none;
  border: none;
  color: #00fff0;
  cursor: pointer;
  text-decoration: underline;
  font-size: 0.85rem;
  padding: 0;
}

.block {
  margin-top: 1rem;
}

@media (max-width: 700px) {
  .wb__spacer {
    display: none;
  }
  .params {
    grid-template-columns: 1fr;
  }
}
</style>
