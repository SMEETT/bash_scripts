<script lang="ts">
	import { loading } from '$lib/loading';
	$: if ($loading.status === 'NAVIGATING') {
		setTimeout(() => {
			if ($loading.status === 'NAVIGATING') {
				$loading.status = 'LOADING';
			}
		}, 200);
	}
</script>

{#if $loading.status === 'LOADING'}
	<div />
{/if}

<style>
	div {
		position: fixed;
		top: 0;
		left: 0;
		background-color: red;
		width: 500px;
		height: 500px;
	}
</style>
