local H = {}

H.get_cursor = function()
	return
	{
		lnum = vim.fn.line("."),
		virtcol = vim.fn.virtcol(".", true)[1],
	}
end

H.set_cursor = function(pos)
	local col = vim.fn.virtcol2col(0, pos.lnum, pos.virtcol)
	if pos.virtcol >= vim.fn.virtcol({pos.lnum, "$"}) then
	-- fix virtcol2col
		col = col + 1
	end

	local off
	local virtcol_max = vim.fn.virtcol({pos.lnum, "$"})
	if pos.virtcol > virtcol_max then
		off = pos.virtcol - virtcol_max
	else
		off = 0
	end

	vim.fn.cursor({pos.lnum, col, off, pos.virtcol})
end

H.width_editable_text = function()
-- https://stackoverflow.com/questions/26315925/get-usable-window-width-in-vim-script
	local wininfo = vim.fn.getwininfo(vim.fn.win_getid())[1]
	local textoff = wininfo.textoff
	local width = wininfo.width
	local width_editable_text = width - textoff
	return width_editable_text
end

H.virtcol_quotient = function(virtcol)
	local width_editable_text = H.width_editable_text()
	-- local virtcol_quotient = virtcol // width_editable_text
	local virtcol_quotient = math.floor(virtcol / width_editable_text)
	return virtcol_quotient
end

H.virtcol_remainder = function(virtcol)
	local width_editable_text = H.width_editable_text()
	local virtcol_remainder = virtcol % width_editable_text
	return virtcol_remainder
end

H.virtcol_max_real = function(lnum)
-- this is **real** virtcol_max, use it with care
	if vim.o.list and vim.opt.listchars:get().eol ~= nil then
		return vim.fn.virtcol({lnum, "$"})
	else
		return
		math.max(1, vim.fn.virtcol({lnum, "$"}) - 1)
	end
end

H.prev_pos = function(pos)
	local width_editable_text = H.width_editable_text()
	local virtcol_quotient = H.virtcol_quotient(pos.virtcol)
	local virtcol_remainder = H.virtcol_remainder(pos.virtcol)

	if virtcol_quotient > 0 then
		return
		{
			lnum = pos.lnum,
			virtcol = pos.virtcol - width_editable_text,
		}
	end
	if pos.lnum == 1 then
		return
		{
		}
	end
	return
	{
		lnum = pos.lnum - 1,
		virtcol = H.virtcol_quotient(H.virtcol_max_real(pos.lnum - 1)) * width_editable_text + virtcol_remainder,
	}
end

H.next_pos = function(pos)
	local width_editable_text = H.width_editable_text()
	local virtcol_quotient = H.virtcol_quotient(pos.virtcol)
	local virtcol_remainder = H.virtcol_remainder(pos.virtcol)

	if virtcol_quotient < H.virtcol_quotient(H.virtcol_max_real(pos.lnum)) then
		return
		{
			lnum = pos.lnum,
			virtcol = pos.virtcol + width_editable_text,
		}
	end
	if pos.lnum == vim.fn.line("$") then
		return
		{
		}
	end
	return
	{
		lnum = pos.lnum + 1,
		virtcol = virtcol_remainder,
	}
end

return H
