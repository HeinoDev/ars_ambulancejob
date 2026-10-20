<script>
  import { fly } from 'svelte/transition'
  import { quintOut } from 'svelte/easing'

  let visible = false
  let remaining = 0
  let medics = 0
  let labels = { unconscious: '', press: '', toRespawn: '', respawnIn: '', medicsOnline: '' }

  $: canRespawn = remaining <= 0
  $: minutes = String(Math.floor(remaining / 60)).padStart(2, '0')
  $: seconds = String(remaining % 60).padStart(2, '0')

  function onMessage(event) {
    const data = event.data
    if (!data || !data.action) return

    if (data.action === 'showDeath') {
      remaining = data.remaining
      medics = data.medics
      labels = data.labels
      visible = true
    } else if (data.action === 'updateDeath') {
      remaining = data.remaining
      medics = data.medics
    } else if (data.action === 'hideDeath') {
      visible = false
    }
  }
</script>

<svelte:window on:message={onMessage} />

{#if visible}
  <div
    class="fixed bottom-4 left-1/2 -translate-x-1/2 z-40 flex w-max items-center gap-2 whitespace-nowrap rounded-md border border-[#333333] bg-[#1e1e1e] px-4 py-2 text-sm text-gray-300 shadow-lg"
    transition:fly|global={{ y: 20, duration: 200, easing: quintOut }}
  >
    <span class="text-white font-medium">{labels.unconscious}</span>
    <span class="text-gray-500">-</span>

    {#if canRespawn}
      <span>{labels.press}</span>
      <div class="rounded border border-[#333333] bg-[#121212] px-2 py-1 text-xs font-medium text-white">G</div>
      <span>{labels.toRespawn}</span>
    {:else}
      <span>{labels.respawnIn}</span>
      <div class="rounded border border-[#333333] bg-[#121212] px-2 py-1 text-xs font-medium tabular-nums text-white">
        {minutes}:{seconds}
      </div>
    {/if}

    <span class="text-gray-500">-</span>
    <span>{labels.medicsOnline.replace('%s', medics)}</span>
  </div>
{/if}
