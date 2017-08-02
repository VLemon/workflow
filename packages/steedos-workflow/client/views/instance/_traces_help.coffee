TracesTemplate.helpers =
	equals: (a, b) ->
		a == b
	empty: (a) ->
		if a
			a.toString().trim().length < 1
		else
			true
	unempty: (a) ->
		if a
			a.toString().trim().length > 0
		else
			false

	append: (a, b) ->
		a + b

	dateFormat: (date) ->
			if Steedos.isMobile() && date?.getFullYear() == (new Date).getFullYear()
				return $.format.date new Date(date), "MM-dd HH:mm"
			else
				return $.format.date new Date(date), "yyyy-MM-dd HH:mm"

	getStepName: (stepId) ->
		step = WorkflowManager.getInstanceStep(stepId)
		if step
			return step.name
		null
	showDeleteButton: (approved) ->
		if approved and approved.type == 'cc' and approved.from_user == Meteor.userId() and approved.is_finished != true and !Session.get("instancePrint")
			return true
		false
	isShowModificationButton: (approved) ->
		approve_admins = Meteor.settings?.public?.workflow?.approve_admins
		if approve_admins?.length
			isShow = approve_admins?.contains Meteor.userId()
		unless isShow
			return false
		return approved.handler == Meteor.userId()
	isEditing: () ->
		 return Template.instance().is_editing?.get()
	isShowDescription: (approved)->
		# debugger
		if TracesTemplate.helpers.isShowModificationButton approved
			return true
		return approved.description?.toString().trim().length > 0
	isCC: (approved) ->
		if approved and approved.type == 'cc'
			return true
		false
	getApproveStatusIcon: (approveJudge) ->
		#已结束的显示为核准/驳回/取消申请，并显示处理状态图标
		approveStatusIcon = undefined
		switch approveJudge
			when 'approved'
				# 已核准
				approveStatusIcon = 'ion ion-checkmark-round'
			when 'rejected'
				# 已驳回
				approveStatusIcon = 'ion ion-close-round'
			when 'terminated'
				# 已取消
				approveStatusIcon = 'fa fa-ban'
			when 'reassigned'
				# 转签核
				approveStatusIcon = 'ion ion-android-contact'
			when 'relocated'
				# 重定位
				approveStatusIcon = 'ion ion-arrow-shrink'
			when 'retrieved'
				# 已取回
				approveStatusIcon = 'fa fa-undo'
			else
				approveStatusIcon = ''
				break
		approveStatusIcon
	getApproveStatusText: (approveJudge) ->
		if Meteor.isServer
			locale = Template.instance().view.template.steedosData.locale
			if locale.toLocaleLowerCase() == 'zh-cn'
				locale = "zh-CN"
		else
			locale = Session.get("TAPi18n::loaded_lang")
		#已结束的显示为核准/驳回/取消申请，并显示处理状态图标
		approveStatusText = undefined
		switch approveJudge
			when 'approved'
				# 已核准
				approveStatusText = TAPi18n.__('Instance State approved', {}, locale)
			when 'rejected'
				# 已驳回
				approveStatusText = TAPi18n.__('Instance State rejected', {}, locale)
			when 'terminated'
				# 已取消
				approveStatusText = TAPi18n.__('Instance State terminated', {}, locale)
			when 'reassigned'
				# 转签核
				approveStatusText = TAPi18n.__('Instance State reassigned', {}, locale)
			when 'relocated'
				# 重定位
				approveStatusText = TAPi18n.__('Instance State relocated', {}, locale)
			when 'retrieved'
				# 已取回
				approveStatusText = TAPi18n.__('Instance State retrieved', {}, locale)
			when 'returned'
				# 已退回
				approveStatusText = TAPi18n.__('Instance State returned', {}, locale)
			when 'readed'
				# 已阅
				approveStatusText = TAPi18n.__('Instance State readed', {}, locale)
			else
				approveStatusText = ''
				break
		approveStatusText
	_t: (key)->
		return TAPi18n.__(key)

	myApproveDescription: (approveId)->
		if Meteor.isClient
			if InstanceManager.isInbox()
				myApprove = InstanceManager.getCurrentApprove()
				if myApprove && myApprove.id == approveId
					return Session.get("instance_my_approve_description") || myApprove?.description || ""
	isForward: (approved) ->
		if approved and approved.type == 'forward'
			return true
		false
	showForwardDeleteButton: (approve) ->
		if approve and approve.type == 'forward' and approve.from_user == Meteor.userId() and !Session.get("instancePrint")
			return true
		false
	markDownToHtml: (markDownString)->
		if markDownString
			renderer = new Markdown.Renderer();
			renderer.link = ( href, title, text ) ->
				return "<a target='_blank' href='#{href}' title='#{title}'>#{text}</a>"
			return Spacebars.SafeString(Markdown(markDownString, {renderer:renderer}))
	isDistribute: (approve) ->
		if approve and approve.type == 'distribute'
			return true
		false
	showDistributeDeleteButton: (approve) ->
		if approve and approve.type == 'distribute' and approve.from_user == Meteor.userId() and !Session.get("instancePrint")
			return true
		false

	finishDateSchema: () ->
		if Steedos.isAndroidOrIOS()
			return new SimpleSchema({
				finish_date: {
					autoform: {
						type: "datetime-local"
					},
					optional: false,
					type: Date
				}
			})
		else
			return new SimpleSchema({
				finish_date: {
					autoform: {
						type: "bootstrap-datetimepicker"
						readonly: true
						dateTimePickerOptions:{
							format: "YYYY-MM-DD HH:mm",
							ignoreReadonly:true,
							widgetPositioning:{
								horizontal: 'right'
							}
						}
					},
					optional: false,
					type: Date
				}
			})

	finishDateValues: () ->
		return {
			finish_date:this.finish_date
		};

if Meteor.isServer
	TracesTemplate.helpers.dateFormat = (date)->
		if date
			utcOffset = Template.instance().view.template.steedosData.utcOffset
			return InstanceReadOnlyTemplate.formatDate(date, utcOffset);

	TracesTemplate.helpers._t = (key)->
		locale = Template.instance().view.template.steedosData.locale
		return TAPi18n.__(key, {}, locale)

	TracesTemplate.helpers.showDeleteButton = (approved) ->
		return false;

TracesTemplate.events =
	'click .cc-approve-remove': (event, template) ->
		event.stopPropagation()
		if event.currentTarget.dataset.calling * 1 != 1
			event.currentTarget.dataset.calling = 1
			$("i",event.currentTarget).addClass("fa-spin")
			instanceId = Session.get('instanceId')
			approveId = event.target.dataset.approve
			# CALL 删除approve函数。
			$("body").addClass("loading")
			Meteor.call 'cc_remove', instanceId, approveId, (err, result) ->
				$("body").removeClass("loading")
				if err
					toastr.error err
					event.currentTarget.dataset.calling = 0
					$("i",event.currentTarget).removeClass("fa-spin")
				if result == true
					toastr.success(TAPi18n.__("remove_cc_approve"));
					if $(".instance-trace-detail-modal").length
						Modal.hide "instance_trace_detail_modal"
				return
			return

	'click .instance-trace-detail-modal .btn-cc-approve-remove': (event, template) ->
		instanceId = Session.get('instanceId')
		approveId = event.target.dataset.approve
		# CALL 删除approve函数。
		$("body").addClass("loading")
		Meteor.call 'cc_remove', instanceId, approveId, (err, result) ->
			$("body").removeClass("loading")
			if err
				toastr.error err
			if result == true
				toastr.success(TAPi18n.__("remove_cc_approve"));
				Modal.hide "instance_trace_detail_modal"
			return
		return

	'click .approve-item': (event, template) ->
		Modal.show "instance_trace_detail_modal", this

	'click .approve-description': (event, template) ->
		Modal.show "instance_trace_detail_modal", this

	'click .instance-trace-detail-modal .btn-close': (event, template) ->
		Modal.hide "instance_trace_detail_modal"

	'click .instance-trace-detail-modal .btn-forward-approve-remove': (event, template) ->
		instanceId = Session.get('instanceId')
		approveId = event.target.dataset.approve
		traceId = event.target.dataset.trace
		# CALL 删除approve函数。
		$("body").addClass("loading")
		Meteor.call 'forward_remove', instanceId, traceId, approveId, (err, result) ->
			$("body").removeClass("loading")
			if err
				toastr.error TAPi18n.__(err.reason)
			if result == true
				toastr.success(TAPi18n.__("instance_approve_forward_remove_success"));
				Modal.hide "instance_trace_detail_modal"
			return
		return

	'click .instance-trace-detail-modal .btn-forward-instance-look': (event, template) ->
		if window.navigator.userAgent.toLocaleLowerCase().indexOf("chrome") < 0
				toastr.warning(TAPi18n.__("instance_chrome_print_warning"))
		else
			forward_space = event.target.dataset.forwardspace
			forward_instance = event.target.dataset.forwardinstance
			Steedos.openWindow(Steedos.absoluteUrl("workflow/space/" + forward_space + "/view/readonly/" + forward_instance))

	'click .btn-modification'	: (event, template) ->
		template.is_editing.set(!template.is_editing.get());
		unless Steedos.isAndroidOrIOS()
			Tracker.afterFlush ->
				# 显示日志的时候把滚动条往下移点，让日期控件显示出一部分，以避免用户看不到日期控件
				$("#instance_trace_detail_modal #finish_input").on "dp.show", () ->
					$(".modal-body").scrollTop(100)
	
	'click .btn-cancelBut' : (event, template) ->
		
		template.is_editing.set(!template.is_editing.get());

	'click .btn-saveBut' : (event, template) ->
		# template.is_editing.set(!template.is_editing.get())

		instanceId = Session.get('instanceId')
		approveId = event.target.dataset.approve
		traceId = event.target.dataset.trace
		opinion_input = $('#opinion_input').val()
		finish_input = AutoForm.getFieldValue("finish_date", "finishDateAutoForm")

		$("body").addClass("loading")
		Meteor.call 'change_approve_info', instanceId, traceId, approveId, opinion_input, finish_input, (err, result)->
			$("body").removeClass("loading")
			if err
				toastr.error TAPi18n.__(err.reason)
			if result == true
				toastr.success(t("instance_approve_modal_modificationsave"))
				Modal.hide "instance_trace_detail_modal"
			return
