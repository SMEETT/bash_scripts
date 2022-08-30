<script>
	import '../app.postcss';
	import { navigating } from '$app/stores';
	import { loading } from '$lib/loading';
	import Loading from '../lib/Loading.svelte';

	$: loading.setNavigate(!!$navigating);
</script>

Loading Status: {$loading.status}
<Loading />

<slot />
